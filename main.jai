dt : float;
u_dt : float;
last_time : float64;
time_scale : float64 = 1.0;

W :: 640;
H :: 480;
main :: () {
    SDL_Init(SDL_INIT_VIDEO);

    //This seems to be optional
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);

    window := SDL_CreateWindow("2D Collision Learning",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        W, H,
        SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN);


    if window == null {
        print("Couldn't create window: %\n", to_string(SDL_GetError()));
        return;
    }

    gl_context := SDL_GL_CreateContext(window);

    if !gl_context {
        print("Couldn't create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }

    //This two seems to be optional
    gl_load(*gl, SDL_GL_GetProcAddress);
    using gl;

    print ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print ("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    // Enable MSAA
    /*
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
    glEnable(GL_MULTISAMPLE);
    */
    //VSync?
    wglSwapIntervalEXT(1);

    quit := false;
    while main := !quit {
        now := seconds_since_init();
        dt = xx ((now - last_time) * time_scale);
        u_dt = xx (now - last_time);

        event : SDL_Event;

        while SDL_PollEvent(*event) {


            if event.type == {
                case SDL_QUIT;
                    quit = true;
                case SDL_KEYUP;
                    if event.key.keysym.sym == SDLK_ESCAPE quit = true;
            }
        }

        render_stuff();
        SDL_GL_SwapWindow(window);

        reset_temporary_storage();
        //print("\nFPS: %",1/dt);

        last_time = now;
    }
    SDL_DestroyWindow(window);
    SDL_Quit();
}
Rect :: struct {
    pos : Vector2;
    size : Vector2;
}
r0 : Rect = .{.{W*0.5,H*0.5},.{50,70}};
r1 : Rect = .{.{W*0.5,H*0.5},.{80,35}};
c : Vector2;
radius : float = 32.0;

render_stuff :: () {
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.1,0.1,0.1,0.1);

    x,y : s32;
    SDL_GetMouseState(*x, *y);
    y = H - y;

    c = (Vector2.{xx x,xx y});

    glColor4f(0.25,0.25,0.25,1.0);
        draw_circle(c,radius);

    colliding, pos := check_circle_aabb_collision(c,radius,r1.pos,r1.size);
    if colliding then
        glColor4f(0.0,1.0,0.0,1.0);
    else
        glColor4f(1.0,1.0,1.0,1.0);

    c = pos;

    //draw_rectangle(r0);
    draw_rectangle(r1);

    draw_circle(c,radius);
}

draw_rectangle :: (r : Rect) {
    glBegin(GL_LINES);
    top_left :=  win_to_device(r.pos + .{-r.size.x,r.size.y}*0.5);
    top_right := win_to_device(r.pos + .{r.size.x,r.size.y}*0.5);
    bot_right := win_to_device(r.pos + .{r.size.x,-r.size.y}*0.5);
    bot_left :=  win_to_device(r.pos + .{-r.size.x,-r.size.y}*0.5);

    glVertex2f(top_left.x,top_left.y);
    glVertex2f(top_right.x,top_right.y);

    glVertex2f(top_right.x,top_right.y);
    glVertex2f(bot_right.x,bot_right.y);

    glVertex2f(bot_right.x,bot_right.y);
    glVertex2f(bot_left.x,bot_left.y);

    glVertex2f(bot_left.x,bot_left.y);
    glVertex2f(top_left.x,top_left.y);

    glEnd();
}

draw_circle :: (p : Vector2, radius : float, count : int = 32) {
    glBegin(GL_LINES);

    for 0..count {
        angle := (cast(float)it / count)*TAU;
        angle2 := (cast(float)(it+1) / count)*TAU;
        p0 := win_to_device(Vector2.{p.x + cos(angle)*radius,p.y + sin(angle)*radius});
        p1 := win_to_device(Vector2.{p.x + cos(angle2)*radius,p.y + sin(angle2)*radius});
        glVertex2f(p0.x,p0.y);
        glVertex2f(p1.x,p1.y);
    }

    glEnd();
}

draw_line :: (p0 : Vector2, p1 : Vector2) {
    glBegin(GL_LINES);

    start := win_to_device(p0);
    end := win_to_device(p1);
    glVertex2f(start.x,start.y);
    glVertex2f(end.x,end.y);
    glEnd();
}

check_point_aabb_collision :: (p0 : Vector2, p1 : Vector2, s1 : Vector2) -> bool {
    return (p0.x > p1.x - s1.x*0.5 && p0.x < p1.x + s1.x*0.5) &&
           (p0.y > p1.y - s1.y*0.5 && p0.y < p1.y + s1.y*0.5);
}

check_aabb_collision :: (p0 : Vector2, s0 : Vector2, p1 : Vector2, s1 : Vector2) -> bool {
    return (p0.x + s0.x*0.5 > p1.x - s1.x*0.5 && p0.x - s0.x*0.5 < p1.x + s1.x*0.5) &&
           (p0.y + s0.y*0.5 > p1.y - s1.y*0.5 && p0.y - s0.y*0.5 < p1.y + s1.y*0.5);
}

check_circle_aabb_collision :: (p0 : Vector2, radius : float, p1 : Vector2, s1 : Vector2) -> bool, direction : Vector2 {
    b_left   := p1.x - s1.x*0.5;
    b_right  := p1.x + s1.x*0.5;

    b_bottom := p1.y + s1.y*0.5;
    b_top    := p1.y - s1.y*0.5;


    closest_point : Vector2;

    closest_point.x = clamp(p0.x, b_left, b_right);
    closest_point.y = clamp(p0.y, b_top, b_bottom);

    dir := normalize(closest_point - p0);

    glColor4f(1.0,1.0,1.0,1.0);
    draw_line(p0,closest_point);
    glColor4f(1.0,0.0,0.0,1.0);
    draw_line(p0,p0-dir*(radius - distance(closest_point,p0)));

    print("\n%",closest_point);

    if check_point_aabb_collision(p0 + dir * radius,p1,s1) {
        return true, p0 - dir*(radius - distance(closest_point,p0));
    }
    return false, p0;
}

closest :: (x : float, a : float, b : float) -> float {
    if abs(x - a) < abs(x - b) then
        return a;
    else
        return b;
}

constraint_distance_aabb :: (p0 : Vector2, s0 : Vector2, p1 : Vector2, s1 : Vector2) -> Vector2 {

    if check_aabb_collision(p0,s0,p1,s1) {

        a_left := p0.x-s0.x*0.5;
        b_left := p1.x-s1.x*0.5;

        a_right := p0.x + s0.x*0.5;
        b_right := p1.x + s1.x*0.5;

        a_top := p0.y-s0.y*0.5;
        b_top := p1.y-s1.y*0.5;

        a_bottom := p0.y + s0.y*0.5;
        b_bottom := p1.y + s1.y*0.5;

        x := min_abs(a_right - b_left,b_right - a_left);
        y := min_abs(a_bottom - b_top,b_bottom - a_top);

        offset : Vector2;

        if x < y then
            offset.x = x * sign(p0.x-p1.x);
        else
            offset.y = y * sign(p0.y-p1.y);

        return p0 + offset;
    }
    return p0;
}

constraint_distance_circle_aabb :: (p0 : Vector2, radius : float, p1 : Vector2, s1 : Vector2) -> Vector2 {


    return p0;
}

sign :: (x : float) -> float {
    return ifx x > 0.0 then 1.0 else -1.0;
}

orthonormalize :: (v : Vector2) -> Vector2 {
    if abs(v.x) > abs(v.y) {
        return .{ifx v.x > 0.0 then 1.0 else -1.0,0};
    }else {
        return .{0,ifx v.y > 0.0 then 1.0 else -1.0};
    }
}

min_abs :: (x : float, y : float) -> float {
    if abs(x) < abs(y) then
        return x;
    else
        return y;
}

to_01 :: (v : Vector2) -> Vector2 {
    return .{(v.x+1.0)*0.5,(v.y+1.0)*0.5};
}

win_to_device :: (v : Vector2) -> Vector2 {
    return .{((v.x/W)*2)-1.0,((v.y/H)*2)-1.0};
}



#import "Basic";
#import "Math";
#import "Window_Creation";
#import "GL";
#import "SDL";
#import "Random";
Input :: #import "Input";

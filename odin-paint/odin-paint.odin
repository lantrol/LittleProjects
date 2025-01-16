package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

main :: proc() {
    WINDOW_WIDTH :: 800
	WINDOW_HEIGHT :: 600

	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"Testing",
		SDL.WINDOWPOS_UNDEFINED,
		SDL.WINDOWPOS_UNDEFINED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.OPENGL},
	)
	if window == nil {
		fmt.eprintln("Error creando ventana")
		return
	}
	defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	gl_context := SDL.GL_CreateContext(window)
	defer SDL.GL_DeleteContext(gl_context)

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

    screen_vert := []glm.vec3{{-1, 1, 0}, {-1, -1, 0}, {1, 1, 0}, {1, -1, 0}}
    screen_elems := []u32{0, 1, 2, 1, 2, 3}

    program, program_ok := gl.load_shaders_source(vert_shader, frag_shader)
    if !program_ok {
        fmt.eprintln("Error cargando shaders")
        return
    }
    else {
        fmt.println("YEEEH")
    }
    defer gl.DeleteProgram(program)

    vao: u32
    gl.CreateVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)
    gl.BindVertexArray(vao)

    vbo, ebo: u32
    gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(
        gl.ARRAY_BUFFER,
        size_of(screen_vert[0])*len(screen_vert),
        raw_data(screen_vert),
        gl.STATIC_DRAW
    )
    
    gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        len(screen_elems)*size_of(u32),
        raw_data(screen_elems),
        gl.STATIC_DRAW
    )

    gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), uintptr(0))


    start_tick := time.tick_now()

    loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// event polling
		event: SDL.Event
		for SDL.PollEvent(&event) {
			// #partial switch tells the compiler not to error if every case is not present
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					// labelled control flow
					break loop
				}
			case .QUIT:
				// labelled control flow
				break loop
			}
		}

		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(0.4, 0.4, 0.4, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(program)
        gl.BindVertexArray(vao)
        gl.DrawElements(gl.TRIANGLES, 3, gl.UNSIGNED_INT, nil)

		//for elem in all_objects {
		//	gl.UseProgram(elem.program)
		//	gl.BindVertexArray(elem.vao)
		//	gl.DrawElements(gl.TRIANGLES, 3, gl.UNSIGNED_INT, nil)
		//	gl.Uniform4f(
		//		elem.uniforms["in_color"].location,
		//		elem.color.x,
		//		elem.color.y,
		//		elem.color.z,
		//		elem.color.w,
		//	)
		//}

		SDL.GL_SwapWindow(window)
	}
}

vert_shader := `
#version 330 core

layout(location=0) in vec3 vert_position;

void main() {
    gl_Position = vec4(vert_position, 1.0); 
}
`

frag_shader := `
#version 330 core

out vec4 out_color;

void main() {
    out_color = vec4(1.0, 1.0, 1.0, 1.0); 
}
`

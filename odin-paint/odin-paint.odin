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

	// Vertex definition and texture creation
	Vertex :: struct {
		pos: glm.vec3,
		tex: glm.vec2,
	}
	screen_vert := []Vertex {
		{{-1, 1, 0}, {0, 1}},
		{{-1, -1, 0}, {0, 0}},
		{{1, 1, 0}, {1, 1}},
		{{1, -1, 0}, {1, 0}},
	}
	screen_elems := []u32{0, 1, 2, 1, 2, 3}
	texture := [?]u8 {
		0 ..< WINDOW_WIDTH * WINDOW_HEIGHT * 3 = 255,
	}

	program, program_ok := gl.load_shaders_source(vert_shader, frag_shader)
	if !program_ok {
		fmt.eprintln("Error cargando shaders")
		return
	}
	defer gl.DeleteProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(screen_vert[0]) * len(screen_vert),
		raw_data(screen_vert),
		gl.STATIC_DRAW,
	)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, tex))


	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(screen_elems) * size_of(screen_elems[0]),
		raw_data(screen_elems),
		gl.STATIC_DRAW,
	)

	canvas: u32
	gl.GenTextures(1, &canvas);defer gl.DeleteTextures(1, &canvas)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, canvas)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl.RGB,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		0,
		gl.RGB,
		gl.UNSIGNED_BYTE,
		&texture[0],
	)

	start_tick := time.tick_now()

	mouse_x, mouse_y: i32
	mouse_bits: u32
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

		// Getting values
		mouse_bits = SDL.GetMouseState(&mouse_x, &mouse_y)

		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(0.4, 0.4, 0.4, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(program)
		gl.BindVertexArray(vao)
		gl.DrawElements(gl.TRIANGLES, i32(len(screen_elems)), gl.UNSIGNED_INT, nil)

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
		gl.Uniform2i(uniforms["mouse_pos"].location, mouse_x, mouse_y)
		gl.Uniform1i(uniforms["screen_height"].location, WINDOW_HEIGHT)
		gl.Uniform1i(uniforms["canvas"].location, 0)

		SDL.GL_SwapWindow(window)
	}
}

vert_shader := `
#version 330 core

layout(location=0) in vec3 vert_position;
layout(location=1) in vec2 in_tex_coord;

out vec2 texCoord;

void main() {
    gl_Position = vec4(vert_position, 1.0);
    texCoord = in_tex_coord;
}
`


frag_shader := `
#version 330 core

uniform ivec2 mouse_pos;
uniform int screen_height;
uniform sampler2D canvas;

in vec2 texCoord;
out vec4 out_color;

void main() {
    ivec2 cur_pos = ivec2(gl_FragCoord.x, screen_height-gl_FragCoord.y);
    out_color = vec4(0., 0., 0., 1.);
    if (length(cur_pos - mouse_pos) < 20) {
        out_color = vec4(1.0, 1.0, 1.0, 1.0); 
    }
    out_color = vec4(texture(canvas, texCoord).xyz, 1.0);
}
`

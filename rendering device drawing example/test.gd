extends  Node

@onready var texr = $TextureRect
@onready var trimt = texr.texture

var tarot_tex = preload("res://assets/tarot.png")
var moon_tex = preload("res://assets/moon.png")

var rd: RenderingDevice
var framebuffer

var pipeline
var clear_color_values
var framebuf_texture
var d_framebuf_texture

var t2drd 

var cam = cam_object.new()
var meshes = []

var light

func _ready():
	
	#rd= RenderingServer.create_local_rendering_device()
	rd= RenderingServer.get_rendering_device()
	
	
	#  <<  --  FRAMEBUFFER  --  >>
	
	var attachments=[]
	
	#  <<  -- COLOR  -- >>
	
	var tex_format:=RDTextureFormat.new()
	var tex_view:=RDTextureView.new()
	tex_format.texture_type=RenderingDevice.TEXTURE_TYPE_2D
	tex_format.height=1024
	tex_format.width=1024
	tex_format.format=RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	#tex_format.usage_bits=(RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT ) 
	tex_format.usage_bits=(131) 
	framebuf_texture = rd.texture_create(tex_format,tex_view)
	print("framebuffe texture : ",rd.texture_is_valid(framebuf_texture))
	
	var af:=RDAttachmentFormat.new()
	af.set_format(tex_format.format)
	af.set_samples(RenderingDevice.TEXTURE_SAMPLES_1)
	af.usage_flags = tex_format.usage_bits
	attachments.push_back(af)
	
	#  WORKS, but is actually slower than with texture_get_data()
	
	#t2drd = Texture2DRD.new()
	#t2drd.texture_rd_rid = RID()
	#t2drd.texture_rd_rid = framebuf_texture	
	
	#  <<  --  DEPTH  --  >>
	
	var dtex_format:=RDTextureFormat.new()
	var dtex_view:=RDTextureView.new()
	dtex_format.texture_type=RenderingDevice.TEXTURE_TYPE_2D
	dtex_format.height=1024
	dtex_format.width=1024
	dtex_format.format=RenderingDevice.DATA_FORMAT_D16_UNORM
	dtex_format.usage_bits=(4) 
	d_framebuf_texture = rd.texture_create(dtex_format,dtex_view)
	print("depth buffer textyre : ", rd.texture_is_valid(d_framebuf_texture))
	
	
	var daf:=RDAttachmentFormat.new()
	daf.set_format(dtex_format.format)
	daf.set_samples(RenderingDevice.TEXTURE_SAMPLES_1)
	#af.usage_flags = RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	daf.usage_flags = dtex_format.usage_bits
	attachments.push_back(daf)
	
	# ---
	
	var framebuf_format=rd.framebuffer_format_create(attachments)
	framebuffer = rd.framebuffer_create([framebuf_texture, d_framebuf_texture],framebuf_format)
	print("framebuffer : ", rd.framebuffer_is_valid(framebuffer))
	
	
	
	#   <<  --  SHADER  --  >>
	var file = FileAccess.open("res://shader_vertex.glsl", FileAccess.READ)
	var vxsh = file.get_as_text()
	file = FileAccess.open("res://shader_fragment.glsl", FileAccess.READ)
	var frsh = file.get_as_text()
	
	var rdssrc = RDShaderSource.new()
	rdssrc.source_vertex = vxsh
	rdssrc.source_fragment = frsh
	
	var rdss = rd.shader_compile_spirv_from_source(rdssrc)
	print(rdss.compile_error_vertex)
	print(rdss.compile_error_fragment)
	
	var shader = rd.shader_create_from_spirv(rdss, "myshader")
	

	
	# <<   --  ATTRIBS  --  >>

	var vertex_attrs = []
	
	#  <<  --  vertices attribs  -->>
	
	var vx_at = RDVertexAttribute.new()
	vertex_attrs.append(vx_at)
	vertex_attrs[0].format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT
	vertex_attrs[0].location = 0
	vertex_attrs[0].stride=4*3
	
	
	#  <<  --  normals attribs  --  >>
	
	var no_at = RDVertexAttribute.new()
	vertex_attrs.append(no_at)
	vertex_attrs[1].format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT
	vertex_attrs[1].location = 1
	vertex_attrs[1].stride=4*3
	
	#  <<  --  UVs attribs  --  >>
	
	var uv_at = RDVertexAttribute.new()
	vertex_attrs.append(uv_at)
	vertex_attrs[2].format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT
	vertex_attrs[2].location = 2
	vertex_attrs[2].stride=4*2
	
	
	var vertex_format = rd.vertex_format_create(vertex_attrs)


	#  <<  --  RENDER PIPELINE --  >>
	var blend = RDPipelineColorBlendState.new()
	blend.attachments.push_back(RDPipelineColorBlendStateAttachment.new())
	
	var dtest = RDPipelineDepthStencilState.new()
	dtest.enable_depth_test = true
	dtest.enable_depth_write = true
	dtest.depth_compare_operator = 1
	
	pipeline = rd.render_pipeline_create(
		shader,
		rd.framebuffer_get_format(framebuffer),
		vertex_format,
		RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
		#RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
		RDPipelineRasterizationState.new(),
		RDPipelineMultisampleState.new(),
		dtest,
		blend
	)
	print(rd.render_pipeline_is_valid(pipeline))
	clear_color_values= PackedColorArray([Color(0,0.03,0.1,1)])
		
		
	var box = mesh_object.new()
	box.create(rd, shader, "box")
	box.tr.origin = Vector3(-2,2,-4)
	box.set_texture(tarot_tex)
	meshes.append(box)
	
	var torus = mesh_object.new()
	torus.create(rd, shader, "torus")
	torus.tr.origin = Vector3(0,0,-2)
	meshes.append(torus)
	
	var sphere = mesh_object.new()
	sphere.create(rd, shader, "sphere")
	sphere.tr.origin = Vector3(0,-2,-5)
	sphere.tr.basis = sphere.tr.basis.scaled(Vector3(2,2,2))
	sphere.set_texture(moon_tex)
	meshes.append(sphere)
	
	
	light = point_light.new()
	light.position = Vector3(0.0,-1.0,2.0)
		
func _process(delta):
	
	var t = Time.get_ticks_msec() *0.001
	meshes[1].tr.basis = meshes[1].tr.basis.rotated(Vector3(1,0,0), delta * 2.0)
	meshes[0].tr.basis = meshes[0].tr.basis.rotated(Vector3(0,1,0), delta)
	
	move_cam(delta)
	var vm = cam.get_mat()
	var pm = cam.get_projmat()

	for m in meshes : 
		rd.buffer_update(m.uniform_buffer, 0, 64, PackedFloat32Array(m.get_mat()).to_byte_array())
		rd.buffer_update(m.uniform_buffer, 64, 64, PackedFloat32Array(vm).to_byte_array())
		rd.buffer_update(m.uniform_buffer, 128, 64, PackedFloat32Array(pm).to_byte_array())
		rd.buffer_update(m.l_uniform_buffer, 0, 28, light.get_buffer())
	
	var draw_list := rd.draw_list_begin(framebuffer, RenderingDevice.INITIAL_ACTION_CLEAR, RenderingDevice.FINAL_ACTION_READ, RenderingDevice.INITIAL_ACTION_CLEAR, RenderingDevice.FINAL_ACTION_DISCARD,clear_color_values)
	rd.draw_list_bind_render_pipeline(draw_list, pipeline)
	
	for m in meshes :
		rd.draw_list_bind_uniform_set(draw_list, m.uniform_set, 0)
		rd.draw_list_bind_vertex_array(draw_list, m.vertex_array)	
		rd.draw_list_bind_index_array(draw_list,m.index_array)
		rd.draw_list_draw(draw_list, true, 2)
	

	rd.draw_list_end(RenderingDevice.BARRIER_MASK_ALL_BARRIERS)
	

	#t2drd.texture_rd_rid = framebuf_texture
	#texr.texture = t2drd
	
	var td=rd.texture_get_data(framebuf_texture,0)
	var img = Image.create_from_data( 1024, 1024, false,  5, td)
	if trimt.get_image() == null:
		trimt.set_image(img)
	else :
		trimt.update(img)



func move_cam(delta) :
	
	var fw = Input.get_action_strength("fw") - Input.get_action_strength("bw")
	var lf = Input.get_action_strength("rg") - Input.get_action_strength("lf")
	var ch = Input.get_action_strength("tl") - Input.get_action_strength("tr")
	
	cam.move(delta, fw, lf, ch)


func transform_to_mat(transf, invert = false) :
	var mat = []
	if invert : 
		transf = transf.inverse()
	mat.append_array([transf.basis.x.x, transf.basis.x.y, transf.basis.x.z, 0,
					transf.basis.y.x, transf.basis.y.y, transf.basis.y.z, 0,
					transf.basis.z.x, transf.basis.z.y, transf.basis.z.z, 0,
					transf.origin.x, transf.origin.y, transf.origin.z, 1])
	return mat

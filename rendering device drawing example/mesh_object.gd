extends Node
class_name mesh_object

var picture = preload("res://assets/color_grid.png")

var vertex_array
var index_array
var arrays
var mesh 
var rd
var v_tex
var uniform_buffer
var l_uniform_buffer
var uniform_set
var uniform
var sampler_uniform := RDUniform.new()

var tr = Transform3D.IDENTITY


func create(in_rd, shader, what = "box") :
	rd = in_rd
	match what :
		"box" :
			mesh = BoxMesh.new()
		"torus" :
			mesh = TorusMesh.new()
		"sphere" :
			mesh = SphereMesh.new()
	
	arrays = mesh.surface_get_arrays(0)
	
	#  << -- INDICES -- >>
	
	var indices = PackedByteArray()
	#var idx_size = cube_arrays.vx_array.size()
	var idx_size = arrays[0].size()
	indices.resize(idx_size * 2)
	var pos:=0
	for x in range(idx_size/3) :
		var c_x = x*3
		indices.encode_s16(pos,c_x)
		indices.encode_s16(pos + 2,c_x + 2)
		indices.encode_s16(pos + 4,c_x +1)
		pos += 6
	
	indices = arrays[12].to_byte_array()
	indices= PackedByteArray()
	indices.resize(arrays[12].size()*2)
	var p = 0
	for idx in arrays[12] :
		indices.encode_s16(p, idx)
		p+= 2
	idx_size = indices.size()/2
		
	var index_buffer=rd.index_buffer_create(idx_size,RenderingDevice.INDEX_BUFFER_FORMAT_UINT16,indices)
	index_array=rd.index_array_create(index_buffer,0,idx_size)
	
	
	#  <<  --  VERTICES --  >>
	
	var vx_bytes = PackedVector3Array()
	var nor_bytes = PackedVector3Array()
	var uv_bytes = PackedVector2Array()
	
	pos = 0
	for i in range(arrays[0].size()) :
		var v = arrays[0][i]
		var n = arrays[1][i]
		var u = arrays[4][i]
		vx_bytes.append(v)
		nor_bytes.append(n)
		uv_bytes.append(u)
		
	var points_bytes = vx_bytes.to_byte_array()
	var norms_bytes = nor_bytes.to_byte_array()
	var uvs_bytes = uv_bytes.to_byte_array()

#   <<  --  mesh buffers  --  >>

	var vertex_buffers := [
		rd.vertex_buffer_create(points_bytes.size(), points_bytes),
		rd.vertex_buffer_create(norms_bytes.size(), norms_bytes),
		rd.vertex_buffer_create(uvs_bytes.size(), uvs_bytes),
	]
	
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
	vertex_array = rd.vertex_array_create(4, vertex_format, vertex_buffers)
	
	
		#  <<  --  TEXTURE UNIFORM  --  >>

	var img = picture.get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBAF)
	var img_pba = img.get_data()
	var width = picture.get_width()
	var height = picture.get_height()
	
	var fmt = RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	#fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	

	v_tex = rd.texture_create(fmt, RDTextureView.new(), [img_pba])
	
	var samp_state = RDSamplerState.new()
	samp_state.repeat_u = 0
	samp_state.repeat_v = 0
	samp_state.repeat_w = 0
	samp_state.mag_filter = 1
	var samp = rd.sampler_create(samp_state)
	
	
	sampler_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	sampler_uniform.binding = 1
	sampler_uniform.add_id(samp)
	sampler_uniform.add_id(v_tex)
	
	
	#  <<  --  MATRICES UNIFORMS  --  >>
	
	var mat = [
		Vector4(1,0,0,0),
		Vector4(0,1,0,0),
		Vector4(0,0,1,0),
		Vector4(0,0,0,1),
		
	]

	var mats = []
	for i in range(3) :
		for e in mat :
			mats.append(e.x)
			mats.append(e.y)
			mats.append(e.z)
			mats.append(e.w)

	
	var input := PackedFloat32Array(mats)
	var input_bytes := input.to_byte_array()
	uniform_buffer = rd.uniform_buffer_create(input_bytes.size(), input_bytes)
	uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	uniform.binding = 0 
	uniform.add_id(uniform_buffer)
	

#  <<  --  LIGHT UNIFORM  --  >>

	var light_pos = Vector3.ZERO
	var light_color = Vector3.ZERO
	var light_intensity = 1.0
	
	var lights = [
		light_pos.x, light_pos.y, light_pos.z, 
		light_color.x, light_color.y, light_color.z, 
		light_intensity
	]
	
	var l_input = PackedFloat32Array(lights)
	var l_input_bytes = input.to_byte_array()
	l_uniform_buffer = rd.uniform_buffer_create(l_input_bytes.size(), l_input_bytes)
	var l_uniform = RDUniform.new()
	l_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	l_uniform.binding = 2 
	l_uniform.add_id(l_uniform_buffer)
	uniform_set = rd.uniform_set_create([uniform, sampler_uniform, l_uniform], shader, 0) 

func set_texture(tex) :
	var img = tex.get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBAF)
	var data = img.get_data()
	rd.texture_update(v_tex, 0, data)

func get_mat() :
	var mat = []
	mat.append_array([tr.basis.x.x, tr.basis.x.y, tr.basis.x.z, 0,
					tr.basis.y.x, tr.basis.y.y, tr.basis.y.z, 0,
					tr.basis.z.x, tr.basis.z.y, tr.basis.z.z, 0,
					tr.origin.x, -tr.origin.y, tr.origin.z, 1])
	return mat


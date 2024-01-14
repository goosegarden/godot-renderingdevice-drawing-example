extends Node

class_name cam_object

var tr = Transform3D.IDENTITY
var cam_fw = 0.0
var cam_lf = 0.0
var cam_h = 0.0

var fov = 105
var aspect_ratio = 1.0
var near = 0.1
var far = 100.0

#var m_f = Transform3D()


func move(delta, fw, lf, ch) :
	var f_change = fw  * delta * 2.0
	var l_change = lf  * delta * 2.0
	var h_change = ch * delta 
	
	cam_fw += f_change
	cam_lf += l_change
	cam_h += h_change
	
	var fw_vector = (-tr.basis.z).normalized()
	var lf_vector = (tr.basis.x).normalized()
	var up_vector = (tr.basis.y).normalized()
	
	tr = tr.translated(lf_vector*l_change + fw_vector * f_change)
	tr.basis = tr.basis.rotated(up_vector, h_change)

func get_projmat() :
	var rpj = Projection.create_perspective(fov,aspect_ratio,near,far)
	var projmat = [
		rpj.x.x, rpj.x.y, rpj.x.z, rpj.x.w, 
		rpj.y.x, rpj.y.y, rpj.y.z, rpj.y.w, 
		rpj.z.x, rpj.z.y, rpj.z.z, rpj.z.w, 
		rpj.w.x, rpj.w.y, rpj.w.z, rpj.w.w, 
		]
	return projmat


func get_mat() :
	var mat = []
	var inv_tr = tr.inverse()
	mat.append_array([inv_tr.basis.x.x, inv_tr.basis.x.y, inv_tr.basis.x.z, 0,
					inv_tr.basis.y.x, inv_tr.basis.y.y, inv_tr.basis.y.z, 0,
					inv_tr.basis.z.x, inv_tr.basis.z.y, inv_tr.basis.z.z, 0,
					inv_tr.origin.x, inv_tr.origin.y, inv_tr.origin.z, 1])
	return mat

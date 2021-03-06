
#include "math.clh"
#include "hit_equations.clh"

float4					spot_projected_color(__global t_obj *obj, int nobjs, float3 v1, __global t_spot *spot, image3d_t texture, __global int2 *texture_sizes);
float4					get_point_color(__global t_obj *objs, __global t_spot *spots, int nspots, int nobjs, int obj_hit,
															float ambiant_light, float3 v, float3 dir, image3d_t texture, __global int2 *texture_sizes);

#define RAY_NUMBER_MAX 20
#define MIN_RAY_ABSORPTION 0.001f

__const sampler_t near_sampler = CLK_NORMALIZED_COORDS_FALSE |
								 CLK_ADDRESS_REPEAT |
								 CLK_FILTER_NEAREST;

__const sampler_t normal_sampler = CLK_NORMALIZED_COORDS_TRUE |
								   CLK_ADDRESS_REPEAT |
								   CLK_FILTER_NEAREST;

float4					spot_projected_color(
						   __global t_obj	*obj,
						   int				nobjs,
						   float3			v1,
						   __global t_spot	*spot,
						   image3d_t		textures,
						   __global int2	*texture_sizes
						)
{
	float3			line;
	float3			ori_tmp;
	float3			dir_tmp;
	float4			ret;
	float			len;
	float			tmp;
	int				i;

	line = spot->pos - v1;
	ret = convert_float4(spot->color) / 255.f;
	i = -1;
	// Iterate throught all the objects to detect the first one hit by the ray
	while (++i < nobjs)
	{
		ori_tmp = vec_mat_mult(obj[i].transform, v1);
		dir_tmp = vec_mat_mult(obj[i].rot_mat, line);
		len = length(dir_tmp);
		dir_tmp = normalize(dir_tmp);
		if (((obj[i].type == SPHERE && sphere_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
			(obj[i].type == PLANE && plane_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
			(obj[i].type == CYLINDER && cylinder_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
			(obj[i].type == CONE && cone_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
			(obj[i].type == TORUS && torus_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
			(obj[i].type == MOEBIUS && moebius_hit(ori_tmp, dir_tmp, &tmp, 0))) &&
				tmp < len)
		{
			float4	obj_color;
			float4	tex_color;
			float2	tex_pos;
			int2	img_size;

			obj_color = convert_float4(obj[i].color) / 255.0f;
			tex_pos = get_surface_pos(obj + i, v1 + tmp * line / len, line);
			if (obj[i].texture_id >= 0 && obj[i].texture_id < (int)get_image_depth(textures))
			{
				img_size = texture_sizes[obj[i].texture_id];
				tex_pos = (float2)((tex_pos - floor(tex_pos)) * img_size);
				tex_color = read_imagef(textures, near_sampler,
						(int4)((int2)fmod(tex_pos, (float2)img_size), obj[i].texture_id, 0));
				obj_color = (float4)(obj_color.rgb * tex_color.rgb, 1.f - (1.f - tex_color.a) * (1.f - obj_color.a));
			}
			obj_color.a = 1.f - (1.f - obj[i].transparency) * (1.f - obj_color.a);
			obj_color.rgb = 1.f - obj_color.rgb * (1.f - obj_color.a);
			if (obj_color.a < MIN_RAY_ABSORPTION)
				return ((float4)0);
			else
			{
				ori_tmp = vec_mat_mult(obj[i].transform, v1 + tmp * line / len);
				dir_tmp = normalize(dir_tmp);
				if ((obj[i].type == SPHERE && sphere_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
					(obj[i].type == PLANE && plane_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
					(obj[i].type == CYLINDER && cylinder_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
					(obj[i].type == CONE && cone_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
					(obj[i].type == TORUS && torus_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
					(obj[i].type == MOEBIUS && moebius_hit(ori_tmp, dir_tmp, &tmp, 1)))
					ret.rgb *= pow(obj_color.rgb, tmp / 2);
				else
					ret.rgb *= obj_color.a * obj_color.rgb;
			}
		}
	}
	return (ret);
}

float4					get_point_color(
								   __global t_obj *objs,
								   __global t_spot *spots,
								   int nspots,
								   int nobjs,
								   int obj_hit,
								   float ambiant_light,
								   float3 v,
								   float3 dir,
								   image3d_t textures,
								   __global int2 *texture_sizes
								  )
{
	float3			normal;
	float3			r_in;
	float3			r_out;
	float			a_in;
	float			brillance;
	float4			lum;
	float4			obj_color;
	float4			tmp;
	float2			tex_pos;
	int2			img_size;
	float4			color;
	int				i;

	lum = (float4)ambiant_light;
	brillance = 0;
	i = -1;
	normal = get_normal(objs + obj_hit, v, dir);
	while (++i < nspots)
	{
		tmp = spot_projected_color(objs, nobjs, v, spots + i, textures, texture_sizes);
		if (tmp.r + tmp.g + tmp.b > MIN_RAY_ABSORPTION)
		{
			r_in = v - spots[i].pos;
			a_in = dot(normalize(r_in), normal);
			if (objs[obj_hit].brillance)
			{
				r_out = normalize(normalize(r_in) - (normal * 2 * a_in));
				brillance = pow(dot(normalize(r_in), normal) , (float)400);
			}
			if (a_in > 0)
				lum += tmp * (float4)(spots[i].lum * a_in / pow(length(r_in), (float)2) + brillance * spots[i].lum);
		}
	}
	tex_pos = get_surface_pos(objs + obj_hit, v, dir);
	obj_color = convert_float4(objs[obj_hit].color) / 255.0f;
	if (objs[obj_hit].texture_id >= 0 && objs[obj_hit].texture_id < (int)get_image_depth(textures))
	{
		img_size = texture_sizes[objs[obj_hit].texture_id];
		tex_pos = (float2)((tex_pos - floor(tex_pos)) * img_size);
		obj_color *= read_imagef(textures, near_sampler,
				(int4)((int2)fmod(tex_pos, (float2)img_size), objs[obj_hit].texture_id, 0));
	}
	color = lum * obj_color;
	return (color);
}

typedef struct		s_ray {
	float3		ori;
	float3		dir;
	float4		absorption;
	float		ref_index;
}					t_ray;

#include "debug.clh"

__kernel void			process_image(
						   __write_only image2d_t		image,
						   __global t_obj				*objs,
						   __global t_spot				*spots,
						   int							nobjs,
						   int							nspots,
						   t_set						set,
						   __read_only image3d_t		textures,
						   __global int2				*texture_sizes
						  )
{
	int2			id;
	float			s;
	int2			img_size;


	id.x = get_global_id(0);
	id.y = get_global_id(1);
	if (set.progressive)
		id = id * 16 + set.iter_pos;
	img_size = (int2)(get_image_width(image), get_image_height(image));
	if (id.x >= img_size.x || id.y >= img_size.y)
		return ;
	s = 1 / tan((float)(set.fov * 0.5 * M_PI_F / 180));

	// Creation of origin and direction vectors of the ray
	t_ray			rays[RAY_NUMBER_MAX];
	int				nrays;
	int				ray;
	int				max_rays;

	rays[0].ori = (float3)((float)(id.x - img_size.x / 2) / (max(img_size.x, img_size.y) / 2) / s,
				   (float)(img_size.y / 2 - id.y) / (max(img_size.x, img_size.y) / 2) / s, 1);
	rays[0].dir = rays[0].ori;
	rays[0].ori = vec_mat_mult(set.cam_mat, rays[0].ori);
	rays[0].dir = normalize(vec_mat_mult(set.cam_mat_rot, rays[0].dir));
	rays[0].absorption = (float4)(1, 1, 1, 1);
	rays[0].ref_index = 1;
	max_rays = min(RAY_NUMBER_MAX, set.max_rays);
	nrays = 1;
	ray = 0;

	float4			color;
	color = (float4)0;

	while (ray < nrays)
	{
		float3			ori;
		float3			dir;
		float3			ori_tmp;
		float3			dir_tmp;
		float4			reflect_amount;
		float			hit;
		float			tmp;
		int				i;
		int				obj_hit;
		float3			v;

		ori = rays[ray].ori;
		dir = rays[ray].dir;
		reflect_amount = rays[ray].absorption;
		ray++;
		if (reflect_amount.x + reflect_amount.y + reflect_amount.z < MIN_RAY_ABSORPTION)
			continue ;

		i = -1;
		hit = -1;
		obj_hit = -1;
		while (++i < nobjs)
		{
			ori_tmp = vec_mat_mult(objs[i].transform, ori);
			dir_tmp = vec_mat_mult(objs[i].rot_mat, dir);
			if (((objs[i].type == SPHERE && sphere_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
				(objs[i].type == PLANE && plane_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
				(objs[i].type == CYLINDER && cylinder_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
				(objs[i].type == CONE && cone_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
				(objs[i].type == TORUS && torus_hit(ori_tmp, dir_tmp, &tmp, 0)) ||
				(objs[i].type == MOEBIUS && moebius_hit(ori_tmp, dir_tmp, &tmp, 0))) &&
					((tmp > 0 && hit < 0) || tmp < hit))
			{
				hit = tmp;
				obj_hit = i;
			}
		}

		// Creates à halo of light when ray passes close to a spots
		float4	shine;
		float	spot_dist;
		float3	ray_diff;
		float3	spot_ray;
		float	tan;

		i = -1;
		while (++i < nspots)
		{
			spot_ray = spots[i].pos - ori;
			spot_dist = length(spot_ray);
			spot_ray = normalize(spot_ray);
			if (dot(dir, spot_ray) > 0 && (hit < 0 || spot_dist / dot(spot_ray, dir) < hit))
			{
				ray_diff = spot_ray - dir;
				tan = fmax(0.f, sqrt(powr(length(ray_diff) * spot_dist, 2) - powr(dot(ray_diff, spot_ray * spot_dist), 2)));
				if (pow(tan, 2) < spots[i].lum / 100.f)
				{
					shine = (spots[i].lum * convert_float4(spots[i].color) / 255.f) * ((0.01f / (0.01f + powr(tan, 2))) - (0.01f / (0.01f + spots[i].lum / 100.f)));
					color += (float4)shine * reflect_amount;
				}
			}
		}

		// If the closest object hit is closer then the far plane, calculate the luminosity add it too the color value
		if (hit > 0)
		{
			float3	normal;
			float4	intensity_mult;
			float4	hit_color;
			float4	tex_color;
			float2	tex_pos;
			int2	img_size;
			float4	absorption;

			v = ori + dir * hit;
			normal = get_normal(objs + obj_hit, v, dir);
			tex_pos = get_surface_pos(objs + obj_hit, v, dir);
			img_size = (int2)1;
			hit_color = convert_float4(objs[obj_hit].color) / 255.0f;
			if (objs[obj_hit].texture_id >= 0 && objs[obj_hit].texture_id < (int)get_image_depth(textures))
			{
				img_size = texture_sizes[objs[obj_hit].texture_id];
				tex_pos = (float2)((tex_pos - floor(tex_pos)) * img_size);
				tex_color = read_imagef(textures, near_sampler,
						(int4)((int2)fmod(tex_pos, (float2)img_size), objs[obj_hit].texture_id, 0));
				hit_color = (float4)(hit_color.rgb * tex_color.rgb, 1.f - (1.f - tex_color.a) * (1.f - hit_color.a));
			}
			hit_color.a = 1.f - (1.f - objs[obj_hit].transparency) * (1.f - hit_color.a);

			// Calculates the refracted/reflected rays
			intensity_mult = reflect_amount;
			intensity_mult *= (1 - objs[obj_hit].reflect) * (1.f - hit_color.a);
			color += get_point_color(objs, spots, nspots, nobjs, obj_hit, set.ambiant_light, v, dir, textures, texture_sizes) * intensity_mult;
			if (nrays < max_rays && hit_color.a > MIN_RAY_ABSORPTION)
			{
				float	cost1;
				float	cost2;
				float	ratio;
				float3	refract_ori;
				float3	refract_dir;
				float	n1;
				float	power_coefficient;

				n1 = objs[obj_hit].ref_index;
				cost1 = dot(dir, normal);
				ratio = 1. / n1;
				cost2 = 1 - ratio * ratio * (1 - cost1 * cost1);
				power_coefficient = pow((n1 - 1) / (n1 + 1), 2);
				power_coefficient = power_coefficient + (1 - power_coefficient) * powr(1 - cost2, 5);
				absorption = (float4)(1.f - hit_color.rgb * (1.f - hit_color.a), 0);
				if (cost2 > 0)
				{
					cost2 = sqrt(cost2);
					refract_dir = normalize(ratio * dir - (ratio * cost1 - cost2) * normal);
					refract_ori = v + refract_dir * 0.01f;
					ori_tmp = vec_mat_mult(objs[obj_hit].transform, refract_ori);
					dir_tmp = vec_mat_mult(objs[obj_hit].rot_mat, refract_dir);
					if ((objs[obj_hit].type == SPHERE && sphere_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
						(objs[obj_hit].type == PLANE && plane_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
						(objs[obj_hit].type == CYLINDER && cylinder_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
						(objs[obj_hit].type == CONE && cone_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
						(objs[obj_hit].type == TORUS && torus_hit(ori_tmp, dir_tmp, &tmp, 1)) ||
						(objs[obj_hit].type == MOEBIUS && moebius_hit(ori_tmp, dir_tmp, &tmp, 1)))
					{
						float3	refract_normal;

						absorption = pow(absorption, tmp * length(dir_tmp) / 2);
						refract_ori = refract_ori + refract_dir * (tmp + 0.01f);
						refract_normal = get_normal(objs + obj_hit, refract_ori, refract_dir);
						cost1 = dot(refract_dir, refract_normal);
						ratio = n1 / 1.;
						cost2 = 1 - ratio * ratio * (1 - cost1 * cost1);
						if (cost2 > 0)
						{
							cost2 = sqrt(cost2);
							dir = normalize(ratio * refract_dir - (ratio * cost1 - cost2) * refract_normal);
						}
					}
					rays[nrays].ori = refract_ori;
					rays[nrays].dir = refract_dir;
					rays[nrays].absorption = reflect_amount * absorption * (1 - power_coefficient);
					nrays++;
				}
			}
			if (nrays < max_rays && (reflect_amount.x + reflect_amount.y + reflect_amount.z) * objs[obj_hit].reflect > MIN_RAY_ABSORPTION)
			{
				float4	reflect_mult;

				if (objs[obj_hit].transparency > MIN_RAY_ABSORPTION)
				{
					float	power_coefficient;
					float	cost1;
					float	n2;

					n2 = objs[obj_hit].ref_index;
					cost1 = dot(dir, normal);
					power_coefficient = pow((1 - n2) / (n2 + 1), 2);
					reflect_mult = (float4)(power_coefficient + (1 - power_coefficient) * pow(1 - cost1, 5));
				}
				else
					reflect_mult = hit_color;
				dir = normalize(dir - (normal * 2 * dot(dir, normal)));
				ori = v;
				rays[nrays].ori = ori + dir * 0.01f;
				rays[nrays].dir = dir;
				rays[nrays].absorption = reflect_amount * objs[obj_hit].reflect * reflect_mult;
				nrays++;
			}
		}
		else
			color += ((1 / (1 - (convert_float4(set.sky_color) / 255))) - 1) * reflect_amount;
	}

	color = clamp(0, 1, color);
	write_imageui(image, id, (uint4)(255.0f * color.r, 255.0f * color.g, 255.0f * color.b, 0));
}

__kernel void	sampler256(
				  __write_only image2d_t	dest_image,
				  __read_only image2d_t		src_image,
				  int2						size,
				  int						iter
				 )
{
	int2			id;
	int2			pos;
	int				bits;
	uint4			color;
	int2			extra_px[16];

	if (size.x * 4 > get_image_width(src_image) ||
			size.y * 4 > get_image_height(src_image))
		return ;
	if ((id.x = get_global_id(0)) >= size.x
			|| (id.y = get_global_id(1)) >= size.y)
		return ;
	bits = (id.x & 2 ? 1 : 0) | (id.y & 2 ? 2 : 0) | (id.x & 1 ? 4 : 0) | (id.y & 1 ? 8 : 0);
	if (iter >= 15)
	{
		int		pxnb;
		int		i;
		uint4	tmp;

		pos = id * 4;
		pxnb = (iter - bits) / 16 + 1;
		tmp = (uint4)(0, 0, 0, 0);
		extra_px[0]  = (int2)(0, 0);
		extra_px[1]  = (int2)(2, 0);
		extra_px[2]  = (int2)(0, 2);
		extra_px[3]  = (int2)(2, 2);
		extra_px[4]  = (int2)(1, 0);
		extra_px[5]  = (int2)(3, 0);
		extra_px[6]  = (int2)(1, 2);
		extra_px[7]  = (int2)(3, 2);
		extra_px[8]  = (int2)(0, 1);
		extra_px[9]  = (int2)(2, 1);
		extra_px[10] = (int2)(0, 3);
		extra_px[11] = (int2)(2, 3);
		extra_px[12] = (int2)(1, 1);
		extra_px[13] = (int2)(3, 1);
		extra_px[14] = (int2)(1, 3);
		extra_px[15] = (int2)(3, 3);
		i = -1;
		while (++i < pxnb)
			tmp += read_imageui(src_image, pos + extra_px[i]);
		color = tmp / pxnb;
	}
	else
	{
		int2		cpos = (int2)(0, 0);

		if (iter >= 1 && bits & 1)
			cpos.x |= 2;
		if (iter >= 2 + (bits & (1 << 1) - 1) && bits & 2)
			cpos.y |= 2;
		if (iter >= 4 + (bits & (1 << 2) - 1) && bits & 4)
			cpos.x |= 1;
		if (iter >= 8 + (bits & (1 << 3) - 1) && bits & 8)
			cpos.y |= 1;
		pos = ((id / 4) * 4 + cpos) * 4;
		color = read_imageui(src_image, pos);
	}
	write_imageui(dest_image, id, (uint4)(color.rgb, 0x00));
}

__kernel void	sampler1(
				  __write_only image2d_array_t	dest_image,
				  __read_only image2d_t			src_image,
				  int2							size,
				  int							thumbnail_id
				 )
{
	int2			id;
	uint4			color;

	if ((id.x = get_global_id(0)) >= size.x
			|| (id.y = get_global_id(1)) >= size.y)
		return ;
	color = read_imageui(src_image, id);
	write_imageui(dest_image, (int4)(id, thumbnail_id, 0), (uint4)(color.rgb, 0x00));
}


__kernel void	paint_gui(
						__write_only image2d_t			screen,
						 t_gui							gui,
						 int2							size,
						 __read_only image2d_t			scene,
						 __read_only image2d_array_t	thumbnails,
						 t_set							set
						)
{
	int2			id;
	float2			npos;
	uint4			color;
	int				buf_pos;

	if ((id.x = get_global_id(0)) >= size.x 
			|| (id.y = get_global_id(1)) >= size.y)
		return ;
	npos = (float2)id / (float2)size * 100;
	buf_pos = id.x + size.x * id.y;
	color = (uint4)(0x22, 0x77, 0xbb, 0x00);
	if (gui.state == SCENE)
		color = read_imageui(scene, near_sampler, id);
	else
	{
		float2	center_dist;
		float2	container_pos;
		float2	mouse_dist;
		float2	tbn_center;

		center_dist = (float2)id / (float2)size - (float2)0.5  - ((float2)(-0.3 + 0.2 * (gui.scene_id % 4), -0.3 + 0.2 * (gui.scene_id / 4)) * ((float)1 - gui.zoom));
		if ((gui.state == ZOOM_SCENE || gui.state == UNZOOM_SCENE) &&
				fabs(center_dist.x) < 0.075 + (0.425 * gui.zoom) &&
				fabs(center_dist.y) < 0.075 + (0.425 * gui.zoom))
		{
			container_pos = center_dist / (float)(0.075 + (0.425 * gui.zoom)) / 2 + (float2)0.5;
			color = read_imageui(scene, normal_sampler, container_pos);
		}
		else
		{
			center_dist = (float2)((float2)id - (float2)(size / 2)) / (float2)size;
			mouse_dist = (float2)((float2)gui.mouse_pos - (float2)(size / 2)) / (float2)size;
			if (fabs(center_dist.x) < 0.4 && fabs(center_dist.y) < 0.4)
			{
				int		tbnnb = get_image_array_size(thumbnails);
				int		i;

				color = (uint4)(0x77, 0x77, 0x77, 0x00);
				i = -1;
				while (++i <  tbnnb)
				{
					tbn_center = (float2)(0.2 * (i % 4 + 1), 0.2 * (i / 4 + 1));
					center_dist = (float2)id / (float2)size - (float2)(tbn_center);
					mouse_dist = (float2)gui.mouse_pos / (float2)size - (float2)(tbn_center);
					if (fabs(center_dist.x) < 0.075 && fabs(center_dist.y) < 0.075)
					{
						container_pos = center_dist / 3 * 20 + (float2)0.5;
						color = read_imageui(thumbnails, normal_sampler, (float4)(container_pos, i, 0));
					}
					else if (fabs(center_dist.x) < 0.075 + 4 / (float)size.x && fabs(center_dist.y) < 0.075 + 4 / (float)size.y)
					{
						if (fabs(mouse_dist.x) < 0.075 && fabs(mouse_dist.y) < 0.075)
							color = (uint4)(0xaf, 0x00, 0x00, 0x00);
						else
							color = (uint4)(0x66, 0x66, 0x66, 0x00);
					}
				}
			}
			else if (fabs(center_dist.x) < 0.4 + 10 / (float)size.x && fabs(center_dist.y) < 0.4 + 10 / (float)size.y)
			{
				if (fabs(mouse_dist.x) < 0.4 && fabs(mouse_dist.y) < 0.4)
					color = (uint4)(0x22, 0x00, 0x00, 0x00);
				else
					color = (uint4)(0x22, 0x22, 0x22, 0x00);
			}
		}
	}
	write_imagef(screen, id, (float4)(convert_float3(clamp(0, 255, color.bgr)) / 255, 0.));
}

__kernel void	clear_buf(__write_only image2d_t buf,
							uchar4 val)
{
	int2		id;

	id.x = get_global_id(0);
	id.y = get_global_id(1);
	write_imageui(buf, id, (uint4)(val.r, val.g, val.b, 0x00));
}

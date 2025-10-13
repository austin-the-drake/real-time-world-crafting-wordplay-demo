
anim_bob += 1;

fade_ease += (highlighted-fade_ease) / 10;

draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, lengthdir_x(fade_ease * 2.5, anim_bob*10), c_white, 1);
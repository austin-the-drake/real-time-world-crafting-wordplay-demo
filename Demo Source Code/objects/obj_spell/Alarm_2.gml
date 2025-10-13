/// @description teleportCaster

caster.x = x;
caster.y = y;
caster.xprevious = x;
caster.yprevious = y;
audio_play_sound(snd_warp, 1, false);
instance_destroy(self, false);
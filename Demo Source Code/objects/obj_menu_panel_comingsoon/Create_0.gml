


elements = [instance_create_layer(x, y+256, layer, obj_panel_button, {
	par: id,
	action: "close",
	text: "OK",
	image_yscale: 0.6875
	})];
image_xscale = 12;
image_yscale = 6;


text = @'This project uses freely available artwork and audio available under various licenses.

"Equatorial Complex" Kevin MacLeod (incompetech.com)                      "Ether Vox" Kevin MacLeod (incompetech.com)                 
Licensed under Creative Commons: By Attribution 4.0 License               Licensed under Creative Commons: By Attribution 4.0 License 
http://creativecommons.org/licenses/by/4.0/                               http://creativecommons.org/licenses/by/4.0/                 

"Sky Game Menu" Eric Matyas (soundimage.org)                              Various Artwork - Kenney (kenney.nl)                        
Licensed under Creative Commons: By Attribution 4.0 License               Public Domain: All copyright waived by creator              
http://creativecommons.org/licenses/by/4.0/                               https://creativecommons.org/publicdomain/zero/1.0/          

Various Sound Effects - David Mckee (soundcloud.com/virix)                "Pixel Combat SFX" Helton Yan (soundcloud.com/heltonyan)    
Licensed under Creative Commons: By Attribution 3.0 License               Licensed under Creative Commons: By Attribution 4.0 License 
http://creativecommons.org/licenses/by/3.0/                               http://creativecommons.org/licenses/by/4.0/                 
';

event_inherited();


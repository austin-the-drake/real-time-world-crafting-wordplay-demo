/// @description Screen shake

// Set a virtual particle to a random position and speed
// Gravity and linear damping will pull the partile towards the origin
// Offsetting the camera by this amount gives a good screen shake effect
x = random_range(-32, 32);
y = random_range(-32, 32);
motion_set(random(360), 7);

#library('roguekit-util');

#source('util/array2d.dart');
#source('util/chain.dart');
#source('util/direction.dart');
#source('util/rect.dart');
#source('util/rng.dart');
#source('util/vec.dart');

// TODO(bob): Where should this go?
sign(num n) {
  return (n < 0) ? -1 : (n > 0) ? 1 : 0;
}

num clamp(num min, num value, num max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
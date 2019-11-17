#include "api_robot2.h"

// robot functions
int detectObstacles();
void bypassingObstacles(int direction);
float currentDistance(Vector3 position);
void turnBaseDirection (int direction);

// utils functions
int arcSin(int x);
void itoa(int number, char* string);
float power(float x, int y);
void printInt(int number);
float squareRoot(float number);

/* robot functions here */

void bypassingObstacles(int direction) {
  if (detectObstacles()) {
    if (direction == 1) { // turn right
      turnBaseDirection(0);
      set_head_servo(2, 270);
    } else if (direction == 0) { // turn left
      turnBaseDirection(1);
      set_head_servo(2, 90);
    }
    while (detectObstacles()) { // move forward until you bypass the obstacle
      set_torque(30, -30); 
    }
  }
}

float currentDistance(Vector3 position) {
  Vector3 current = {.x = 11, .y = 11, .z = 11};

  float xDistance = power(current.x - position.x, 2);
  float zDistance = power(current.z - position.z, 2);

  return squareRoot(xDistance + zDistance);
}

int detectObstacles(){
  if (get_us_distance() != -1) { // if some distance is found, then there are obstacles
    return 1;
  }

  return 0; // no obstacles
}

void turnBaseDirection (int direction) {
  if (direction == 1) { // direction = counter-clockwise
    set_engine_torque(1, 30); // turns the direction for walle's body
  } else if (direction == 0) { // direction = clockwise
    set_engine_torque(0, 30); // turns the direction for walle's body
  }
}

/* ultis functions here */

void itoa(int number, char* string){
  int i = 0;
  int rem;
  int length = 0;
  int n;

  if(number == 0){
    string[0] = '0';
    string[1] = '\0';
    return;
  }
  else{
    if(number < 0){
      n = -number;
      number = -number;
    }
    else
      n = number;
  }
  
  while (n != 0){
    length++;
    n /= 10;
  }
  for (int i = 0; i < length; i++){
    rem = number % 10;
    number = number / 10;
    string[length - (i + 1)] = rem + '0';
  }
  
  string[length] = '\0';

}

float power(float x, int y) {
  if(y == 0)
    return 1;

  float result = 1;
  for (int i = 0; i < y; i++)
    result = result*x;
  
  return result;
}

void printInt(int number){
  char string[10];
  itoa(number, string);

  if(number < 0)
    puts("-");
  puts(string);
}

float squareRoot(float number) {
  float error = 0.00001; //define the precision of your result
  float s = number;

  while (s - (number/s) > error) //loop until precision satisfied
    s = (s + (number/s)) / 2;
  return s;
}

// this function receives a value for a sin and it returns it's arcsin (both values are in radians)
int arcSin(int x) {
  if (x > 0 && x < 0.4) {
    return ((0.4115/0.4)*x);
  } 
  else if (x > 0.4 && x < 0.565) {
    return ((1.145*(x-4)) + 0.4115);
  }
  else if (x > 0.565 && x < 0.7004) {
    return ((1.29689*(x-0.565)) + 0.6004);
  }
  else if (x > 0.7004 && x < 0.8014) {
    return ((1.52*(x-0.7004)) + 0.776);
  }
  else if (x > 0.8014 && x < 0.8675) {
    return ((1.82*(x-0.8014)) + 0.9296);
  }
  else if (x > 0.8675 && x < 0.9318) {
    return ((2.3188*(x-0.8675)) + 1.0502);
  }
  else if (x > 0.9318 && x < 0.9758) {
    return ((3.4340*(x-0.9318)) + 1.1993);
  }
  else if (x > 0.9758 && x < 0.995) {
    return ((6.27*(x-0.995)) + 1.4708);
  }
  else if (x > 0.995 && x < 1) {
    return ((20*(x-1)) + 1.57);
  }
}

int main(){
  while(1==1){
    unsigned int time = get_time();
    printInt((int) time);
    puts("\n");
  }

  return 0;
}

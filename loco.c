#include "api_robot2.h"


/* HEADERS */
// robot functions
void bypassingObstacles(int direction);
int detectDangerLocation(Vector3 currentPosition, Vector3 dangerousLocation);
int detectObstacles();
float distance(Vector3 position, Vector3 friendPosition);
int isVisited(int index);
int getAngleToTurn(int myAngle, Vector3 currentPosition, Vector3 friends_locations);
void moveWalle(int angToTurn);
void printPosition(Vector3 printPosition);
void turnBaseDirection (int direction);
void wait(int seconds);

// utils functions
double arcSin(double x);
void itoa(int number, char* string);
float power(float x, int y);
void printInt(int number);
float squareRoot(float number);

/* global variables */
int visitedFriends[20];

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

int detectDangerLocation(Vector3 currentPosition, Vector3 dangerousLocation) {
  if ((currentPosition.x == (dangerousLocation.x - 10) || currentPosition.x == (dangerousLocation.x + 10)) && (currentPosition.z == (dangerousLocation.z - 10))) {
    turnBaseDirection(0); // turn base direction clockwise to bypass without danger
    return 1;
  } else if ( (currentPosition.x == (dangerousLocation.x - 10) || currentPosition.x == (dangerousLocation.x + 10)) && currentPosition.z == (dangerousLocation.z + 10)) {
    turnBaseDirection(1); // turn base direction counter-clockwise to bypass without danger
    return 1;
  }

  return 0; // no danger
}

int detectObstacles(){
  if (get_us_distance() != -1) { // if some distance is found, then there are obstacles
    return 1;
  }

  return 0; // no obstacles
}

float distance(Vector3 position, Vector3 friendPosition) {
  float xDistance = (friendPosition.z - position.z)*(friendPosition.z - position.z);
  float yDistance = (friendPosition.x - position.x)*(friendPosition.x - position.x);

  return squareRoot(xDistance + yDistance);
}

// check if the friend posistion has already been visited
int isVisited(int index){
  if(visitedFriends[index] == 1)
    return 1;
  else
    return 0;
}

int getAngleToTurn(int myAngle, Vector3 currentPosition, Vector3 friends_locations) {
  int deltaX = friends_locations.x - currentPosition.x; // calculates distance from friend at y coordinate
  int deltaZ = friends_locations.z - currentPosition.z; // calculates distance from friend at x coordinate
  float distanceFromFriend = distance(currentPosition, friends_locations); // calculates distance from friend

  double resultForObtainingTheta = deltaX / distanceFromFriend;
  double theta = arcSin(resultForObtainingTheta); // angle between walle's position and friend's position

  int angGrau = (int) (180*theta/3.1415); // convert from radian to degrees

  if (deltaZ < 0) { 
    if (deltaX >= 0) {
        angGrau = 180 - angGrau; // If walle is in the second quadrant, convert to the right degree
    } else {
        angGrau = -180 - angGrau; // If walle is in the fourth quadrant, convert to the right degree
    }
  }

  int angToTurnRight = myAngle - angGrau;
  int angToTurn = angToTurnRight; // Final angle to turn into friend's position

  return angToTurn;
}

void moveWalle(int angToTurn) {
  int dirToTurn = 1; // 1 -> right / -1 -> left

  if (angToTurn > 180) {
    angToTurn = 360 - angToTurn; // If the angle to turn is greater than 180, it is better to rotate counterclockwise
    dirToTurn = -1; // turn left
  } else if (angToTurn < -180) {
    angToTurn = 360 + angToTurn;
  } else if (angToTurn < 0) {
    angToTurn = -angToTurn;
    dirToTurn = -1; // turn left
  }

  if (angToTurn >= 5 || angToTurn < -5) { // If the angle is correct adjusted (5 degree security rate)
    if (dirToTurn = 1) { // turn right
      set_torque(8, -8);
    } else {
      set_torque(-8, 8); // else, turn left
    }
  } else {
    set_torque(10, 10);
  }
}

void printPosition(Vector3 position){
  printInt(position.x);
  puts(", ");
  printInt(position.y);
  puts(", ");
  printInt(position.z);
  puts("\n");

  return;
}

void turnBaseDirection (int direction) {
  if (direction == 1) { // direction = counter-clockwise
    set_engine_torque(1, 30); // turns the direction for walle's body
  } else if (direction == 0) { // direction = clockwise
    set_engine_torque(0, 30); // turns the direction for walle's body
  }
}

void wait(int seconds) { // function to set a timeout
  int initial = get_time();
  int final = get_time();

  while(final - initial < seconds*1000) {
    final = get_time();
  }

  return;
}

/* utils functions here */
/* ================================================================ */

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
  float error = 0.1; //define the precision of your result
  float s = number;

  while (s - (number/s) > error) //loop until precision satisfied
    s = (s + (number/s)) / 2;
  return s;
}

// this function receives a value for a sin and it returns it's arcsin (both values are in radians)
double arcSin(double x) {
  int m = 1;
  if (x < 0) {
		x = -x;
		m = -1;
  } 
  if (x >= 0 && x <= 0.4) {
		return m*((0.4115/0.4)*x);
  } 
  else if (x > 0.4 && x <= 0.565) {
		return m*((1.145*(x-0.4)) + 0.4115);
  }
  else if (x > 0.565 && x <= 0.7004) {
		return m*((1.29689*(x-0.565)) + 0.6004);
  }
  else if (x > 0.7004 && x <= 0.8014) {
		return m*((1.52*(x-0.7004)) + 0.776);
  }
  else if (x > 0.8014 && x <= 0.8675) {
		return m*((1.82*(x-0.8014)) + 0.9296);
  }
  else if (x > 0.8675 && x <= 0.9318) {
		return m*((2.3188*(x-0.8675)) + 1.0502);
  }
  else if (x > 0.9318 && x <= 0.9758) {
		return m*((3.4340*(x-0.9318)) + 1.1993);
  }
  else if (x > 0.9758 && x <= 0.995) {
		return m*((6.27*(x-0.995)) + 1.4708);
  }
  else if (x > 0.995 && x <= 1) {
		return m*((20*(x-1)) + 1.57);
  }
}

int main(){
  int numOfFriends = sizeof(friends_locations) / sizeof(friends_locations[0]);
  int numOfVisitedFriends = 0;
  int currentFriendIndex;

  set_torque(-4,-4);
  wait(3);

  Vector3 friend;
  Vector3 currentPosition;
  Vector3 angles;

  float minimum = 2000;

  get_current_GPS_position(&currentPosition);

  // for(int i = 0; i < numOfFriends; i++){
  //   if(!isVisited(i)){
  //     if(distance(currentPosition, friends_locations[i]) < minimum){
  //       friend.x = friends_locations[i].x;
  //       friend.y = friends_locations[i].y;
  //       friend.z = friends_locations[i].z;
  //       currentFriendIndex = i;
  //       minimum = distance(currentPosition, friends_locations[i]);
  //     }
  //   }
  // }

  friend = friends_locations[numOfVisitedFriends];

  while(numOfVisitedFriends < numOfFriends) {
    get_gyro_angles(&angles);
    printInt(angles.y);
    puts("\n\0");
    get_current_GPS_position(&currentPosition); // gets walle's current position
    int angle = getAngleToTurn(angles.y, currentPosition, friend);

    moveWalle(angle);

    if (distance(currentPosition, friend) <= 5) {
      friend = friends_locations[numOfVisitedFriends++];
    }
  }

  return 0;
}

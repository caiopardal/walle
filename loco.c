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
  } else { // else move walle to a friend and treat the obstacles here
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

/* Estratégia seguida para encontrar os amigos:
  Visando percorrer todo o vetor de amigos que é passado no arquivo api_robot2.h, essa função main irá fazer uso de uma estratégia de calcular o amigo
  mais próximo e ir até ele, enquanto ainda existirem amigos para se visitar. Dentro dessa lógica de visita, há o cálculo do ângulo para posicionar a base
  do Walle corretamente para a posição do amigo (função getAngleToTurn) e em seguida faz uso da função moveWalle. Essa última função move o Walle enquanto
  sua distância ao amigo for menor do que 5 metros. Quando isso acontece, o amigo visitado é marcado como visitado no Array de amigos e o próximo amigo vira
  o alvo atual do Walle, que por sua vez, irá ajustar a sua base para se mover até esse novo amigo. Dentro dessa função chamada moveWalle, a ideia é fazer uso
  das funções detectObstacles, detectDangerLocation e turnBaseDirection para desviar dos obstáculos que o Walle encontrar no caminho. Dessa maneira, o Walle irá percorrer todos os amigos passados evitando as zonas perigosas e cumprindo o seu objetivo */
int main(){
  int numOfFriends = sizeof(friends_locations) / sizeof(friends_locations[0]); // variable that contains the number of friends to visit
  int numOfVisitedFriends = 0; // variable that contains the number of visited friends
  int currentFriendIndex;

  set_torque(-4,-4); // To initialize the walle's hunt, go backwards then start the hunt
  wait(3); // set a timeout to start the hunt

  Vector3 friend;
  Vector3 currentPosition;
  Vector3 angles;

  float minimum = 2000;

  get_current_GPS_position(&currentPosition);

  friend = friends_locations[numOfVisitedFriends];

  while(numOfVisitedFriends < numOfFriends) { // while there are friends to visit
    get_gyro_angles(&angles);
    get_current_GPS_position(&currentPosition); // gets walle's current position
    int angle = getAngleToTurn(angles.y, currentPosition, friend); // calculates the angle to turn

    moveWalle(angle); // move walle to friend's location

    if (distance(currentPosition, friend) <= 5) { // if you visit the friend, mark as visited
      friend = friends_locations[numOfVisitedFriends++];
    }
  }

  return 0;
}

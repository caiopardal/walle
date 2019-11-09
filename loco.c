#include "api_robot2.h"

void turnBaseDirection (int direction) {
  if (direction == 1) { // direction = counter-clockwise
    set_engine_torque(1, 30); // turns the direction for walle's body
  } else if (direction == 0) { // direction = clockwise
    set_engine_torque(0, 30); // turns the direction for walle's body
  }
}

int detectObstacles () {
  if (get_us_distance() != -1) { // if some distance is found, then there are obstacles
    return 1;
  }

  return 0; // no obstacles
}

void bypassingObstacles (int direction) {
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
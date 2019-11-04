# functions descriptions are in api_robot.h

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar as coordenadas (x, y, z);
# return -> void (the return is in the a0)
.globl get_current_GPS_position
get_current_GPS_position:
  li a7, 19
  ecall

  ret

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar os ângulos de Euler (x, y, z);
# return -> void (the return is in the a0)	
.globl get_gyro_angles
get_gyro_angles:
  li a7, 20
  ecall

  ret

# args -> none
# return -> a0: tempo do sistema em milisegundos;
.globl get_time
get_time:
  li a7, 21
  ecall

  ret

# args -> a0: tempo do sistema, em milisegundos;
# return -> void;
.globl set_time
set_time:
  li a7, 22
  ecall

  ret

# args -> a0: Descritor do arquivo, a1: Endereço de memória do buffer a ser escrito, a2: Número de bytes a serem escritos;
# return -> a0: Número de bytes efetivamente escritos;
.globl puts
puts:
  li a7, 64
  ecall

  ret
#include "uart.h"

volatile int * uart_read_reg = (int*)UART_RX_O;
volatile int * uart_write_reg = (int*)UART_TX_I;
volatile int * uart_control_reg = (int*)UART_CONT;
volatile int * uart_status_reg = (int*)UART_STAT;

void init_uart(int baudrate){
    //TODO: ADD CHECKS WHETHER THE BAUDRATE IS VALID, OR REWORK UART MODULE TO ALLOW FOR FULLY VARIABLE BAUDRATES
    //TODO: ADD ABILITY TO UART TO CHOOSE BETWEEN AUTOBAUD RECEPTION AND FIXED BAUDRATE RECEPTION
    *uart_control_reg = (27000000 / baudrate) << 1;
}

void uart_send(char* to_send){
    int i = 0;
    while(to_send[i] != '\0'){
        if(!uart_tx_isfull()){
            //TX Buffer not full
            *uart_write_reg = to_send[i];
            i++;
        }
    }
}

int uart_rx_isempty(){
    return ((*uart_status_reg >> 1) & 1);
}

int uart_rx_isfull(){
    return ((*uart_status_reg >> 3) & 1);
}

int uart_tx_isfull(){
    return ((*uart_status_reg >> 2) & 1);
}

void uart_read(char dest[9]){
    int i = 0;
    while(!uart_rx_isempty() && i < 8){
        dest[i] = *uart_read_reg;
        i++;
    }
    dest[i] = '\0';
}

char uart_read_byte(){
    if(!uart_rx_isempty())
        return *uart_read_reg;
    return 0;
}

int queue_rx(){
    return (*uart_status_reg >> 4) & 0xF; 
}

int queue_tx(){
    return (*uart_status_reg >> 8) & 0xF; 
}
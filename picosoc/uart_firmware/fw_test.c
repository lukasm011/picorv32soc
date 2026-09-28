#include "uart.h"

int main(){
    init_uart(1000000);
    while(1){
        int flush;
        char to_send[2];
        to_send[1] = '\0';
        if(!uart_rx_isempty()){
            to_send[0] = queue_rx() + 48;
            if(queue_rx() == 4){
                while(!uart_rx_isempty())
                    flush = uart_read_byte();
            }
            uart_send(to_send);
        }
    }
    return 0;
}
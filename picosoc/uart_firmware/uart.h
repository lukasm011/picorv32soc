#ifndef UART_H
#define UART_H
#define MEMWORDS 1024
#define UART_RX_O ((MEMWORDS) * 4)
#define UART_TX_I ((MEMWORDS + 1) * 4)
#define UART_CONT ((MEMWORDS + 2) * 4)
#define UART_STAT ((MEMWORDS + 3) * 4)
void uart_send(char* to_send);
int uart_rx_isempty();
int uart_tx_isfull();
int uart_rx_isfull();
void uart_read(char dest[9]);
char uart_read_byte();
void init_uart(int baudrate);
int queue_rx();
int queue_tx();
#endif
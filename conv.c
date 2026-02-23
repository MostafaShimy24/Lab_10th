#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "xparameters.h"
#include "sleep.h"
#include <stdint.h>

// ---------------- GPIO IDs ----------------
#define GPIO_DATA_ID     XPAR_AXI_GPIO_0_DEVICE_ID
#define GPIO_OUT_ID      XPAR_AXI_GPIO_1_DEVICE_ID
#define GPIO_START_ID    XPAR_AXI_GPIO_2_DEVICE_ID
#define GPIO_WRITE_ID    XPAR_AXI_GPIO_3_DEVICE_ID
#define GPIO_INDEX_ID    XPAR_AXI_GPIO_4_DEVICE_ID
#define GPIO_CLEAR_ID    XPAR_AXI_GPIO_5_DEVICE_ID

// ---------------- Channels ----------------
#define X_CH        1
#define W_CH        2
#define RESULT_CH   1
#define DONE_CH     2
#define START_CH    1
#define WRITE_CH    1
#define INDEX_CH    1
#define CLEAR_CH    1

#define N 40

XGpio gpio_data;
XGpio gpio_out;
XGpio gpio_start;
XGpio gpio_write;
XGpio gpio_index;
XGpio gpio_clear;

// ------------------------------------------------
// Load Memory Function
// ------------------------------------------------
void load_memory(int8_t x_vals[], int8_t w_vals[])
{
    XGpio_DiscreteWrite(&gpio_write, WRITE_CH, 1);
    for(int i = 0; i < N; i++)
    {
        XGpio_DiscreteWrite(&gpio_index, INDEX_CH, i);
        XGpio_DiscreteWrite(&gpio_data, X_CH, (uint32_t)(x_vals[i] & 0xFF));
        XGpio_DiscreteWrite(&gpio_data, W_CH, (uint32_t)(w_vals[i] & 0xFF));
    }
    XGpio_DiscreteWrite(&gpio_write, WRITE_CH, 0);
}

// ------------------------------------------------
// Start + Wait + Read
// ------------------------------------------------
int run_accelerator()
{
    int done = 0;

    XGpio_DiscreteWrite(&gpio_start, START_CH, 1);
    XGpio_DiscreteWrite(&gpio_start, START_CH, 0);
    while(!done)
    {
        done = XGpio_DiscreteRead(&gpio_out, DONE_CH) & 0x1;
    }
    int result = (int)XGpio_DiscreteRead(&gpio_out, RESULT_CH);
    // Clear done
    XGpio_DiscreteWrite(&gpio_clear, CLEAR_CH, 1);
    XGpio_DiscreteWrite(&gpio_clear, CLEAR_CH, 0);
    return result;
}

// ------------------------------------------------
// MAIN
// ------------------------------------------------
int main()
{
    init_platform();
    xil_printf("\n==== Convolution ====\n");
    // Initialize GPIOs
    XGpio_Initialize(&gpio_data,  GPIO_DATA_ID);
    XGpio_Initialize(&gpio_out,   GPIO_OUT_ID);
    XGpio_Initialize(&gpio_start, GPIO_START_ID);
    XGpio_Initialize(&gpio_write, GPIO_WRITE_ID);
    XGpio_Initialize(&gpio_index, GPIO_INDEX_ID);
    XGpio_Initialize(&gpio_clear, GPIO_CLEAR_ID);

    XGpio_SetDataDirection(&gpio_data, X_CH, 0x0);
    XGpio_SetDataDirection(&gpio_data, W_CH, 0x0);
    XGpio_SetDataDirection(&gpio_out, RESULT_CH, 0xFFFFFFFF);
    XGpio_SetDataDirection(&gpio_out, DONE_CH, 0xFFFFFFFF);
    XGpio_SetDataDirection(&gpio_start, START_CH, 0x0);
    XGpio_SetDataDirection(&gpio_write, WRITE_CH, 0x0);
    XGpio_SetDataDirection(&gpio_index, INDEX_CH, 0x0);
    XGpio_SetDataDirection(&gpio_clear, CLEAR_CH, 0x0);
    int8_t x[N];
    int8_t w[N];
    int expected;
    int result;

    // ================= TEST 1 =================
    xil_printf("\nTest 1: x=1..40, w=1\n");
    expected = 0;
    for(int i=0;i<N;i++)
    {
        x[i] = i+1;
        w[i] = 1;
        expected += (i+1);
    }
    load_memory(x,w);
    result = run_accelerator();
    xil_printf("Expected = %d | Result = %d\n", expected, result);
    xil_printf(result == expected ? "PASS\n" : "FAIL\n");

    // ================= TEST 2 =================
    xil_printf("\nTest 2: x=2, w=3\n");
    expected = 0;
    for(int i=0;i<N;i++)
    {
        x[i] = 2;
        w[i] = 3;
        expected += 2*3;
    }
    load_memory(x,w);
    result = run_accelerator();
    xil_printf("Expected = %d | Result = %d\n", expected, result);
    xil_printf(result == expected ? "PASS\n" : "FAIL\n");


    // ================= TEST 3 =================
    xil_printf("\nTest 3: x=i, w=i\n");
    expected = 0;
    for(int i=0;i<N;i++)
    {
        x[i] = i;
        w[i] = i;
        expected += i*i;
    }
    load_memory(x,w);
    result = run_accelerator();
    xil_printf("Expected = %d | Result = %d\n", expected, result);
    xil_printf(result == expected ? "PASS\n" : "FAIL\n");

    xil_printf("\n==== All Tests Finished ====\n");

    while(1);
}

#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

int main(void)
{
    while (1) {
        printk("Hello World from my own MCXN947 project!\n");
        k_sleep(K_SECONDS(1));
    }

    return 0;
}
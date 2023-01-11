/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef __GOODIX_H__
#define __GOODIX_H__

#include <linux/gpio/consumer.h>
#include <linux/i2c.h>
#include <linux/input.h>
#include <linux/input/mt.h>
#include <linux/input/touchscreen.h>
#include <linux/regulator/consumer.h>

/* Register defines */
#define GOODIX_REG_MISCTL_DSP_CTL		0x4010
#define GOODIX_REG_MISCTL_SRAM_BANK		0x4048
#define GOODIX_REG_MISCTL_MEM_CD_EN		0x4049
#define GOODIX_REG_MISCTL_CACHE_EN		0x404B
#define GOODIX_REG_MISCTL_TMR0_EN		0x40B0
#define GOODIX_REG_MISCTL_SWRST			0x4180
#define GOODIX_REG_MISCTL_CPU_SWRST_PULSE	0x4184
#define GOODIX_REG_MISCTL_BOOTCTL		0x4190
#define GOODIX_REG_MISCTL_BOOT_OPT		0x4218
#define GOODIX_REG_MISCTL_BOOT_CTL		0x5094

#define GOODIX_REG_FW_SIG			0x8000
#define GOODIX_FW_SIG_LEN			10

#define GOODIX_REG_MAIN_CLK			0x8020
#define GOODIX_MAIN_CLK_LEN			6

#define GOODIX_REG_COMMAND			0x8040
#define GOODIX_CMD_SCREEN_OFF			0x05

#define GOODIX_REG_SW_WDT			0x8041

#define GOODIX_REG_REQUEST			0x8043
#define GOODIX_RQST_RESPONDED			0x00
#define GOODIX_RQST_CONFIG			0x01
#define GOODIX_RQST_BAK_REF			0x02
#define GOODIX_RQST_RESET			0x03
#define GOODIX_RQST_MAIN_CLOCK			0x04
/*
 * Unknown request which gets send by the controller aprox.
 * every 34 seconds once it is up and running.
 */
#define GOODIX_RQST_UNKNOWN			0x06
#define GOODIX_RQST_IDLE			0xFF

#define GOODIX_REG_STATUS			0x8044

#define GOODIX_GT1X_REG_CONFIG_DATA		0x8050
#define GOODIX_GT9X_REG_CONFIG_DATA		0x8047
#define GOODIX_REG_ID				0x8140
#define GOODIX_READ_COOR_ADDR			0x814E
#define GOODIX_REG_BAK_REF			0x99D0

#define GOODIX_ID_MAX_LEN			4
#define GOODIX_CONFIG_MAX_LENGTH		240
#define GOODIX_MAX_KEYS				7

enum goodix_irq_pin_access_method {
	IRQ_PIN_ACCESS_NONE,
	IRQ_PIN_ACCESS_GPIO,
	IRQ_PIN_ACCESS_ACPI_GPIO,
	IRQ_PIN_ACCESS_ACPI_METHOD,
};

struct goodix_ts_data;

struct goodix_chip_data {
	u16 config_addr;
	int config_len;
	int (*check_config)(struct goodix_ts_data *ts, const u8 *cfg, int len);
	void (*calc_config_checksum)(struct goodix_ts_data *ts);
};

struct goodix_ts_data {
	struct i2c_client *client;
	struct input_dev *input_dev;
	struct input_dev *input_pen;
	const struct goodix_chip_data *chip;
	const char *firmware_name;
	struct touchscreen_properties prop;
	unsigned int max_touch_num;
	unsigned int int_trigger_type;
	struct regulator *avdd28;
	struct regulator *vddio;
	struct gpio_desc *gpiod_int;
	struct gpio_desc *gpiod_rst;
	int gpio_count;
	int gpio_int_idx;
	enum gpiod_flags gpiod_rst_flags;
	char id[GOODIX_ID_MAX_LEN + 1];
	char cfg_name[64];
	u16 version;
	bool reset_controller_at_probe;
	bool load_cfg_from_disk;
	int pen_input_registered;
	struct completion firmware_loading_complete;
	unsigned long irq_flags;
	enum goodix_irq_pin_access_method irq_pin_access_method;
	unsigned int contact_size;
	u8 config[GOODIX_CONFIG_MAX_LENGTH];
	unsigned short keymap[GOODIX_MAX_KEYS];
	u8 main_clk[GOODIX_MAIN_CLK_LEN];
	int bak_ref_len;
	u8 *bak_ref;
};

int goodix_i2c_read(struct i2c_client *client, u16 reg, u8 *buf, int len);
int goodix_i2c_write(struct i2c_client *client, u16 reg, const u8 *buf, int len);
int goodix_i2c_write_u8(struct i2c_client *client, u16 reg, u8 value);
int goodix_send_cfg(struct goodix_ts_data *ts, const u8 *cfg, int len);
int goodix_int_sync(struct goodix_ts_data *ts);
int goodix_reset_no_int_sync(struct goodix_ts_data *ts);

int goodix_firmware_check(struct goodix_ts_data *ts);
bool goodix_handle_fw_request(struct goodix_ts_data *ts);
void goodix_save_bak_ref(struct goodix_ts_data *ts);

#endif

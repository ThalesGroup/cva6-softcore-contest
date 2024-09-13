// SPDX-License-Identifier: GPL-2.0+
/*
 * (C) Copyright 2017 Rob Clark
 */

#include <common.h>
#include <dm.h>
#include <fdtdec.h>
#include <fdt_support.h>
#include <log.h>
#include <video.h>
#include <asm/global_data.h>

#include <asm/io.h>

#define BASE_ADDR_VGA  0x50000000


	
struct reg_config_vga {
	unsigned int		ctrl;			/* 0x00 */
	unsigned int		clk_div;			/* 0x04 */
	
	unsigned int		hactive;			/* 0x08 */
	unsigned int		hfront_porch;			/* 0x0c */
	unsigned int		hsync_len;			/* 0x00 */
	unsigned int		hback_porch;			/* 0x04 */
	
	unsigned int		vactive;			/* 0x08 */
	unsigned int		vfront_porch;			/* 0x0c */
	unsigned int		vsync_len;			/* 0x00 */
	unsigned int		vback_porch;			/* 0x04 */
	
	unsigned int		*Low_start_addr;			/* 0x28 */
	unsigned int		High_start_addr;			/* 0x2c */
	unsigned int		Frame_size;			/* 0x30 */
	unsigned int		Burst_length;			/* 0x34 */
	
	unsigned int		Offset;			/* 0x38 */
	unsigned int		PIXEL_CLK;			/* 0x3c */
	};
	
	
	
	
static void vga_set_timing(struct reg_config_vga *regs, int vga_mode){
	if (vga_mode==0){
		printf("Format 800x600@60Hz 2 \r\n");
		
		writel(800 , &regs->hactive);
		writel(40, &regs->hfront_porch);
		writel(128, &regs->hsync_len);
		writel(88, &regs->hback_porch);

		writel(600, &regs->vactive);
		writel(1, &regs->vfront_porch);
		writel(4, &regs->vsync_len);
		writel(23, &regs->vback_porch);
	}
	
	    
	
	if (vga_mode==3){
		printf("Format 1280x1024@60Hz \r\n");
		
		writel(1280 , &regs->hactive);
		writel(48, &regs->hfront_porch);
		writel(112, &regs->hsync_len);
		writel(248, &regs->hback_porch);

		writel(1024, &regs->vactive);
		writel(1, &regs->vfront_porch);
		writel(3, &regs->vsync_len);
		writel(38, &regs->vback_porch);
	}
	printf("%s\n", __func__);
    
}

static int simple_video_probe(struct udevice *dev)
{
	struct video_uc_plat *plat = dev_get_uclass_plat(dev);
	struct video_priv *uc_priv = dev_get_uclass_priv(dev);
	const void *blob = gd->fdt_blob;
	const int node = dev_of_offset(dev);
	const char *format;
	
	
	printf("%s(%s)\n", __func__, dev->name);
/*	
	fdt_addr_t base;
	fdt_size_t size;
	base = fdtdec_get_addr_size_auto_parent(blob, dev_of_offset(dev->parent),
			node, "reg", 0, &size, false);
	if (base == FDT_ADDR_T_NONE) {
		debug("%s: Failed to decode memory region\n", __func__);
		return -EINVAL;
	}

	debug("%s: base=%llx, size=%llu\n", __func__, base, size);

	
	plat->base = base;
	plat->size = size;
	*/
	plat->base = 0xa0000000;
	plat->size = 960000;//1920*1080*2

	video_set_flush_dcache(dev, true);

	debug("%s: Query resolution...\n", __func__);

	uc_priv->xsize = fdtdec_get_uint(blob, node, "width", 0);
	uc_priv->ysize = fdtdec_get_uint(blob, node, "height", 0);
	uc_priv->rot = 0;

	format = fdt_getprop(blob, node, "format", NULL);
	debug("%s: %dx%d@%s\n", __func__, uc_priv->xsize, uc_priv->ysize, format);

	if (strcmp(format, "r5g6b5") == 0) {
		uc_priv->bpix = VIDEO_BPP16;
	} else if (strcmp(format, "a8b8g8r8") == 0) {
		uc_priv->bpix = VIDEO_BPP32;
	} else {
		printf("%s: invalid format: %s\n", __func__, format);
		return -EINVAL;
	}
	
/*	struct reg_config_vga *regs = BASE_ADDR_VGA ;
	
	int vga_mode=3;
	
	writel(1, &regs->clk_div);
	vga_set_timing(regs,vga_mode);
	writel((uint64_t)plat->base, &regs->Low_start_addr);
	//vga_set_start_addr(regs,plat->base);
	writel(0, &regs->High_start_addr);
	

	writel(0x280000, &regs->Frame_size);
	writel(0xff, &regs->Burst_length);

	writel(0x28, &regs->Offset);
	writel(0x01, &regs->PIXEL_CLK);
	writel(1, &regs->ctrl);
*/	

	return 0;
}

static const struct udevice_id simple_video_ids[] = {
	{ .compatible = "simple-framebuffer" },
	{ }
};

U_BOOT_DRIVER(simple_video) = {
	.name	= "simple_video",
	.id	= UCLASS_VIDEO,
	.of_match = simple_video_ids,
	.probe	= simple_video_probe,
};

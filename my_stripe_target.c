#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/bio.h>
#include <linux/device-mapper.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("Odd/Even (Stripe) DM Target");

struct my_stripe_context {
    struct dm_dev *even_dev;
    struct dm_dev *odd_dev;
};

static int my_stripe_ctr(struct dm_target *ti, unsigned int argc, char **argv) {
    struct my_stripe_context *ctx = NULL;
    fmode_t mode = FMODE_READ | FMODE_WRITE;

    if (argc != 2) {
        ti->error = "Invalid argument count";
        return -EINVAL;
    }

    ctx = kmalloc(sizeof(struct my_stripe_context), GFP_KERNEL);
    if (ctx == NULL) {
        ti->error = "Cannot allocate context";
        return -ENOMEM;
    }

    if (dm_get_device(ti, argv[0], mode, &ctx->even_dev)) {
        ti->error = "Cannot get EVEN device";
        kfree(ctx);
        return -EINVAL;
    }

    if (dm_get_device(ti, argv[1], mode, &ctx->odd_dev)) {
        ti->error = "Cannot get ODD device";
        dm_put_device(ti, ctx->even_dev);
        kfree(ctx);
        return -EINVAL;
    }

    ti->private = ctx;
    ti->max_io_len = 1;
    ti->num_flush_bios = 2;

    printk(KERN_INFO "FINAL_FIX: constructor complete.\n");
    return 0;
}

static void my_stripe_dtr(struct dm_target *ti) {
    struct my_stripe_context *ctx = ti->private;
    dm_put_device(ti, ctx->even_dev);
    dm_put_device(ti, ctx->odd_dev);
    kfree(ctx);
    printk(KERN_INFO "FINAL_FIX: destructor complete.\n");
}

static int my_stripe_map(struct dm_target *ti, struct bio *bio) {
    struct my_stripe_context *ctx = ti->private;
    sector_t logical_sector = bio->bi_iter.bi_sector;
    sector_t physical_sector;

    if (logical_sector & 1) {
        bio->bi_bdev = ctx->odd_dev->bdev;
    } else {
        bio->bi_bdev = ctx->even_dev->bdev;
    }

    physical_sector = logical_sector >> 1;
    bio->bi_iter.bi_sector = physical_sector;

    return DM_MAPIO_REMAPPED;
}

static struct target_type my_stripe_target = {
    .name     = "my_stripe",
    .version  = {1, 0, 0},
    .module   = THIS_MODULE,
    .ctr      = my_stripe_ctr,
    .dtr      = my_stripe_dtr,
    .map      = my_stripe_map,
};

static int __init my_stripe_init(void) {
    int result = dm_register_target(&my_stripe_target);
    if (result < 0) {
        printk(KERN_ALERT "Failed to register my_stripe target\n");
    } else {
        printk(KERN_INFO "FINAL_FIX: target registered.\n");
    }
    return result;
}

static void __exit my_stripe_exit(void) {
    dm_unregister_target(&my_stripe_target);
    printk(KERN_INFO "FINAL_FIX: target unregistered.\n");
}

module_init(my_stripe_init);
module_exit(my_stripe_exit);

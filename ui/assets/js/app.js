new Vue({
  el: "#app",
  data: function () {
    return {
      positions: [
        "top-right",
        "top-center",
        "top-left",
        "middle-right",
        "middle-center",
        "middle-left",
        "bottom-right",
        "bottom-center",
        "bottom-left",
      ],
      selectedPosition: "top-right",
      notificationContainers: {},
      notificationCount: 0,
      maxNotifications: 1, // เพิ่มการจำกัดจำนวนไว้ตรงนี้ (ปรับตัวเลขได้ตามต้องการ)
      useBackground: true,
      contentAlignment: "start",
      isRTL: false,
      notificationTimers: {},
    };
  },
  created: function () {
    this.positions.forEach((position) => {
      this.$set(this.notificationContainers, position, []);
    });

    window.addEventListener("message", (event) => {
      // แก้ไขตรงนี้: เปลี่ยนจาก BLN_NOTIFY เป็น MTN_NOTIFY
      if (event.data.type === "MTN_NOTIFY") {
        this.PlaySound(event.data.options?.customSound);
        this.notify(event.data.options);
      } 
      else if (event.data.type === "MTN_NOTIFY_ITEM") {
      this.PlaySound(event.data.options?.customSound);
      event.data.options.isItem = true; // กำหนดค่า isItem เป็น true
      this.notify(event.data.options);
      }
      // แก้ไขตรงนี้: เปลี่ยนจาก BLN_NOTIFY_KEY_PRESSED เป็น MTN_NOTIFY_KEY_PRESSED
      else if (event.data.type === "MTN_NOTIFY_KEY_PRESSED") {
        this.handleKeyPress(
          event.data.notificationId,
          event.data.key,
          event.data.placement
        );
      }
    });
  },
  methods: {
    notify: function (options) {
      var id =
        options.id !== undefined
          ? parseInt(options.id)
          : this.notificationCount++;
      var duration = options.duration || 5000;

      const notification = {
        id: id,
        title: options.title !== undefined ? options.title : "Notification",
        description: options.description || null,
        icon: options.icon || null,
        color: options.color || "#ffffff", // รับค่าสี ถ้าไม่มีให้ใช้สีเขียว #ffffff เป็นค่าเริ่มต้น
        titleColor: options.titleColor || "#006eff",  // สีหัวข้อ (ถ้าไม่ส่งมา ใช้สีขาว)
        useBackground:
          options.useBackground !== undefined
            ? options.useBackground
            : this.useBackground,
        contentAlignment: options.contentAlignment || this.contentAlignment,
        isRTL: options.isRTL !== undefined ? options.isRTL : this.isRTL,
        isItem: options.isItem || false, // <--- บรรทัดนี้ (isItem)
        duration: duration,
        remainingTime: duration / 1000,
        progress: {
          enabled: options.progress?.enabled ?? false,
          type: options.progress?.type || "bar",
          color: options.progress?.color || "#fff",
          value: 1,
        },
        keyActions: options.keyActions || {},
      };

      const placement = options.placement || this.selectedPosition;
      this.$set(this.notificationContainers, placement, [
        notification,
        ...this.notificationContainers[placement],
      ]);

      // --- ส่วนที่แก้ไข: ลบอันเก่าออกถ้าเกินลิมิต ---
      if (this.notificationContainers[placement].length > this.maxNotifications) {
        const oldestNotification = this.notificationContainers[placement][this.notificationContainers[placement].length - 1];
        if (oldestNotification) {
            this.removeNotification(placement, oldestNotification.id);
        }
      }
      // ------------------------------------------

      if (notification.progress.enabled) {
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            notification.progress.value = 0;
          });
        });
        if (notification.progress.type === "circle") {
          const startTime = Date.now();
          const interval = setInterval(() => {
            const elapsed = Date.now() - startTime;
            notification.remainingTime = Math.max(
              0,
              (duration - elapsed) / 1000
            );

            if (elapsed >= duration) {
              clearInterval(interval);
            }
          }, 100);
        }
      }
      const timerId = setTimeout(() => {
        this.removeNotification(placement, id);
      }, duration);
      
      this.notificationTimers[id] = timerId;
    },
    removeNotification: function (position, id) {
      if (this.notificationTimers[id]) {
        clearTimeout(this.notificationTimers[id]);
        delete this.notificationTimers[id];
      }

      var index = this.notificationContainers[position].findIndex(
        (n) => n.id === id
      );
      if (index !== -1) {
        this.notificationContainers[position].splice(index, 1);
      }
      this.PlaySound();
    },
    getIconUrl: function (icon) {
      if (icon.includes("//")) {
        return icon;
      }
      return `./assets/imgs/icons/${icon}.png`;
    },
    PlaySound(soundData) {
      fetch(`https://${GetParentResourceName()}/playSound`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(soundData || {}),
      });
    },
    handleKeyPress: function (notificationId, key, placement) {
      const searchId = parseInt(notificationId);

      const notification = this.notificationContainers[placement]?.find(
        (n) => n.id === searchId
      );
      
      if (notification) {
        this.$emit("notification-key-pressed", { notificationId, key });
        this.removeNotification(placement, searchId);
      }
    },
  },
});
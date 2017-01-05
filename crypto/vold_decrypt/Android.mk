# Copyright (C) 2017 TeamWin Recovery Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

ifeq ($(TW_CRYPTO_USE_SYSTEM_VOLD),true)
    # Just enabled, so only vold + vdc
    services :=
else
    # Additional services needed by vold
    services := $(TW_CRYPTO_USE_SYSTEM_VOLD)
endif

# List of .rc files for each additional service
rc_files := $(foreach item,$(services),init.recovery.vold_decrypt.$(item).rc)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := $(LOCAL_MODULE)

# Add additional .rc files and imports into init.recovery.vold_decrypt.rc
# Note: any init.recovery.vold_decrypt.{service}.rc that are not default
#       in crypto/vold_decrypt should be in the device tree
LOCAL_POST_INSTALL_CMD := $(hide) \
    $(foreach item, $(rc_files), \
        sed -i '1iimport \/$(item)' "$(TARGET_ROOT_OUT)/$(LOCAL_MODULE)"; \
        if [ -f "$(LOCAL_PATH)/$(item)" ]; then \
            cp -f "$(LOCAL_PATH)/$(item)" "$(TARGET_ROOT_OUT)"/; \
        fi; \
    )

# Cannot send to TARGET_RECOVERY_ROOT_OUT since build system wipes init*.rc
# during ramdisk creation and only allows init.recovery.*.rc files to be copied
# from TARGET_ROOT_OUT thereafter
LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT)
LOCAL_MODULE := init.recovery.vold_decrypt.rc
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES

include $(BUILD_PREBUILT)

include $(CLEAR_VARS)

LOCAL_CFLAGS := -Wall

ifneq ($(services),)
    LOCAL_CFLAGS += -DTW_CRYPTO_SYSTEM_VOLD_SERVICES='"$(services)"'
endif

ifeq ($(TW_CRYPTO_SYSTEM_VOLD_DEBUG),true)
    # Enabling strace will expose the password in the strace logs!!
    LOCAL_CFLAGS += -DTW_CRYPTO_SYSTEM_VOLD_DEBUG
endif

ifeq ($(TW_CRYPTO_SYSTEM_VOLD_DISABLE_TIMEOUT),true)
    LOCAL_CFLAGS += -DTW_CRYPTO_SYSTEM_VOLD_DISABLE_TIMEOUT
endif

LOCAL_SRC_FILES := vold_decrypt.cpp
LOCAL_SHARED_LIBRARIES := libcutils

LOCAL_MODULE := libvolddecrypt
LOCAL_MODULE_TAGS := optional

include $(BUILD_STATIC_LIBRARY)

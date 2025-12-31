#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>
#include <cstdlib>

#include "flutter_window.h"
#include "utils.h"

#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>
auto bdw = bitsdojo_window_configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP);

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Ensure only one instance is running
  const wchar_t kUniqueMutexName[] = L"Local\\CyreneMusicInstanceMutex";
  HANDLE mutex = CreateMutex(nullptr, TRUE, kUniqueMutexName);
  (void)mutex;
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing_window = FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
    if (existing_window) {
      // If the window is hidden (e.g., minimized to tray), show it first
      if (!IsWindowVisible(existing_window)) {
        ShowWindow(existing_window, SW_SHOW);
      }
      
      // If minimized, restore it
      if (IsIconic(existing_window)) {
        ShowWindow(existing_window, SW_RESTORE);
      }
      
      // Bring to foreground
      SetForegroundWindow(existing_window);
    }
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // 设置 AppUserModelID，确保 SMTC 可以正确识别应用
  // 格式: 公司名.应用名.子产品.版本号
  ::SetCurrentProcessExplicitAppUserModelID(L"CyreneMusic.MusicPlayer.Desktop.1");
  
  // 获取当前进程的窗口句柄（稍后设置）
  // 这将在 FlutterWindow 创建后设置应用显示名称

  flutter::DartProject project(L"data");

  // 启用 Impeller 渲染引擎以支持高刷新率
  // 通过环境变量设置引擎开关，Impeller 使用 Direct3D 后端
  // 可以更好地匹配显示器刷新率（如 120Hz、144Hz 等）
  _putenv_s("FLUTTER_ENGINE_SWITCHES", "1");
  _putenv_s("FLUTTER_ENGINE_SWITCH_1", "enable-impeller=true");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"cyrene_music", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Initialize bitsdojo_window
  auto window_handle = window.GetHandle();
  if (window_handle != nullptr) {
    bitsdojo_window_configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

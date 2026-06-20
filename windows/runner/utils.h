#ifndef FLUTTER_WINDOW_CLIENT_H_
#define FLUTTER_WINDOW_CLIENT_H_

#include <windows.h>

#include <string>

// Creates a console for the process, and redirects stdout and stderr to
// it for both the runner and the Flutter library if present.
void CreateAndAttachConsole();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. Returns an empty std::string on failure.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty std::vector<std::string> on failure.
std::vector<std::string> GetCommandLineArguments();

#endif  // FLUTTER_WINDOW_CLIENT_H_ 
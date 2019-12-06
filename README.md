# TIniSettings
TIniSettings for FreePascal

The idea was taken from the article

ООП и паттерны проектирования: практическое применение http://yumata.blogspot.com/2010/01/blog-post.html

Using in lpr
to create a new empty Config

program ... 
uses ... 
uIniSettings, uAppConfig,

if not AppConfig.CheckExists or AppConfig.IsEmpty then 
begin 
  AppConfig.Update; 
  Application.Terminate; 
  exit; 
end;

An example of TAppConfig is included

:: Usage: just pull the file to run this bat
@echo off
certutil -hashfile "%~1" md5
certutil -hashfile "%~1" sha1
@pause
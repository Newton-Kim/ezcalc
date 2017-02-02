#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([ezcalc], [1.0.0], [newton.s.kim@gmail.com])
AM_INIT_AUTOMAKE([subdir-objects])
LT_INIT
AC_CONFIG_SRCDIR([src/main.cc])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIRS([m4])
AC_PREFIX_DEFAULT(/usr/local)

# Checks for programs.
AC_PROG_CXX
AC_PROG_LEX
AC_PROG_YACC
AC_PROG_LIBTOOL

# Checks for libraries.
# FIXME: Replace `main' with a function in `-lezvm':
AC_CHECK_LIB([ezvm], [main])
# FIXME: Replace `main' with a function in `-lfl':
AC_CHECK_LIB([fl], [main])

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL

# Checks for library functions.
AC_CHECK_FUNCS([strdup strtol])

AC_CONFIG_FILES([Makefile
                 src/Makefile])
AC_OUTPUT

%bcond_without tests
%bcond_without weak_deps

%global __os_install_post %(echo '%{__os_install_post}' | sed -e 's!/usr/lib[^[:space:]]*/brp-python-bytecompile[[:space:]].*$!!g')
%global __provides_exclude_from ^@(InstallationPrefix)/.*$
%global __requires_exclude_from ^@(InstallationPrefix)/.*$

Name:           @(Package)
Version:        @(Version)
Release:        @(RPMInc)%{?dist}%{?release_suffix}
Summary:        ROS @(Name) package

License:        @(License)
@[if Homepage and Homepage != '']URL:            @(Homepage)@\n@[end if]@
Source0:        %{name}-%{version}.tar.gz
@[if NoArch]@\nBuildArch:      noarch@\n@[end if]@

Requires:       %{name}-runtime%{?_isa?} = %{version}-%{release}
@[for p in ExportDepends]Requires:       @p@\n@[end for]@
@[for p in Replaces]Obsoletes:      @p@\n@[end for]@
@[for p in Provides]Provides:       @p@\n@[end for]@

%description
@(Description)

%package runtime
Summary:        Runtime-only files for @(Name) package
@[for p in ExecDepends]Requires:       @p@\n@[end for]@
@[for p in BuildDepends]BuildRequires:  @p@\n@[end for]@
@[for p in Conflicts]Conflicts:      @p@\n@[end for]@
@[if TestDepends]@\n%if 0%{?with_tests}
@[for p in TestDepends]BuildRequires:  @p@\n@[end for]@
%endif@\n@[end if]@
@[if Supplements]@\n%if 0%{?with_weak_deps}
@[for p in Supplements]Supplements:    @p@\n@[end for]@
%endif@\n@[end if]@

%description runtime
Runtime-only files for @(Name) package

%prep
%autosetup -p1

%build
# In case we're installing to a non-standard location, look for a setup.sh
# in the install tree and source it.  It will set things like
# CMAKE_PREFIX_PATH, PKG_CONFIG_PATH, and PYTHONPATH.
if [ -f "@(InstallationPrefix)/setup.sh" ]; then . "@(InstallationPrefix)/setup.sh"; fi
mkdir -p .obj-%{_target_platform} && cd .obj-%{_target_platform}
%cmake3 \
    -UINCLUDE_INSTALL_DIR \
    -ULIB_INSTALL_DIR \
    -USYSCONF_INSTALL_DIR \
    -USHARE_INSTALL_PREFIX \
    -ULIB_SUFFIX \
    -DCMAKE_INSTALL_PREFIX="@(InstallationPrefix)" \
    -DCMAKE_PREFIX_PATH="@(InstallationPrefix)" \
    -DSETUPTOOLS_DEB_LAYOUT=OFF \
%if !0%{?with_tests}
    -DBUILD_TESTING=OFF \
%endif
    -DINSTALL_EXAMPLES=OFF \
    -DSECURITY=ON \
    -DAPPEND_PROJECT_NAME_TO_INCLUDEDIR=ON \
    ..

%make_build

%install
# In case we're installing to a non-standard location, look for a setup.sh
# in the install tree and source it.  It will set things like
# CMAKE_PREFIX_PATH, PKG_CONFIG_PATH, and PYTHONPATH.
if [ -f "@(InstallationPrefix)/setup.sh" ]; then . "@(InstallationPrefix)/setup.sh"; fi
%make_install -C .obj-%{_target_platform}

for f in \
    @(InstallationPrefix)/include/ \
    @(InstallationPrefix)/share/ament_index/resource_index/packages/ \
    @(InstallationPrefix)/share/@(Name)/cmake/ \
    @(InstallationPrefix)/share/@(Name)/package.dsv \
    @(InstallationPrefix)/share/@(Name)/package.xml \
; do
    if [ -e %{buildroot}$f ]; then echo $f; fi
done > devel_files

%if 0%{?with_tests}
%check
# Look for a Makefile target with a name indicating that it runs tests
TEST_TARGET=$(%__make -qp -C .obj-%{_target_platform} | sed "s/^\(test\|check\):.*/\\1/;t f;d;:f;q0")
if [ -n "$TEST_TARGET" ]; then
# In case we're installing to a non-standard location, look for a setup.sh
# in the install tree and source it.  It will set things like
# CMAKE_PREFIX_PATH, PKG_CONFIG_PATH, and PYTHONPATH.
if [ -f "@(InstallationPrefix)/setup.sh" ]; then . "@(InstallationPrefix)/setup.sh"; fi
CTEST_OUTPUT_ON_FAILURE=1 \
    %make_build -C .obj-%{_target_platform} $TEST_TARGET || echo "RPM TESTS FAILED"
else echo "RPM TESTS SKIPPED"; fi
%endif

%files -f devel_files

%files runtime
@[for lf in LicenseFiles]%license @lf@\n@[end for]@
@(InstallationPrefix)
%exclude @(InstallationPrefix)/include/
%exclude @(InstallationPrefix)/share/ament_index/resource_index/packages/
%exclude @(InstallationPrefix)/share/@(Name)/cmake
%exclude @(InstallationPrefix)/share/@(Name)/package.dsv
%exclude @(InstallationPrefix)/share/@(Name)/package.xml

%changelog@
@[for change_version, (change_date, main_name, main_email) in changelogs]
* @(change_date) @(main_name) <@(main_email)> - @(change_version)
- Autogenerated by Bloom
@[end for]

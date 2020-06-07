# RPM spec file meant for packaging via cargo-rpm
#
# initially generated with `cargo rpm init` and then modified for
# our use.

%define __spec_install_post %{nil}
%define __os_install_post %{_dbpath}/brp-compress
%define debug_package %{nil}

# if the _unitdir macro is not defined, set it to the standard systemd unit path
%{!?_unitdir: %define _unitdir /usr/lib/systemd/system}

# the @@ strings here will be replaced with meaningful values when the build
# is done via cargo-rpm
Name: rust-packaging-example
Summary: Example rust program for packaging demo purposes
Version: @@VERSION@@
Release: @@RELEASE@@%{?dist}
License: ASL 2.0
Group: System Environment/Daemons
Source0: %{name}-%{version}.tar.gz
URL: https://github.com/anupdhml/rust-packaging-example

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%description
%{summary}

%prep
%setup -q

%build
# we rely on binaries pre-built alrady in the Source0 tar file
# so this section is empty for us.

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a * %{buildroot}
#tree %{_topdir} # only for debugging

%clean
rm -rf %{buildroot}

%post
%systemd_post rust-packaging-example.service
# TODO reuse the postinst script from deb packaging here

%preun
%systemd_preun rust-packaging-example.service

%postun
%systemd_postun_with_restart rust-packaging-example.service

# the dir macros used here should line up with path names that are part of
# package.metadata.rpm.files configuration in the project's cargo manifest
%files
%defattr(-,root,root,-)

%{_bindir}/*

%doc %{_datadir}/doc/%{name}/README.md
%license %{_datadir}/licenses/%{name}/LICENSE

%config(noreplace) %{_sysconfdir}/%{name}/logger.yaml
%config %{_sysconfdir}/%{name}/config/*

%{_unitdir}/rust-packaging-example.service

# TODO enable after %post is fully done
#%dir %{_localstatedir}/log/%{name}/

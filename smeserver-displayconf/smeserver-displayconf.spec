Summary: Display configuration panel for SME Server
%define name smeserver-displayconf
Name: %{name}
%define version 0.3
%define release 1
Version: %{version}
Release: %{release}
License: GPL
Group: Configuration/Display
Source: %{name}-%{version}.tar.gz
# Patch0: 
Packager: Pascal Schirrmann <schirrms@schirrms.net>
BuildRoot: /var/tmp/%{name}-%{version}-%{release}-buildroot
BuildRequires: e-smith-devtools
BuildArchitectures: noarch
Requires: e-smith-base
Requires: SMEServer >= 9.2
AutoReqProv: no

%description
Adds a Display Configuration panel to the SME server-manager.

%changelog
* Sat Jul 01 2017 John Crisp <jcrisp@safeandsoundit.co.uk>
- Convert for Koozali SME v9

* Sat May 15 2004 Pascal Schirrmann <schirrms@schirrms.net>
- Choice of undef and blank representation
- smarter choice of display selection
- some complementary informations from /etc/group and /etc/password
- current size of the Homedir
- allow the install on SME 5.6
- [0.0.2-00]
* Fri May 14 2004 Pascal Schirrmann <schirrms@schirrms.net>
- initial alpha release
- [0.0.1-00]

%prep
%setup
# %patch0 -p1

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root   ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f e-smith-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist

%clean
cd ..
rm -rf %{name}-%{version}

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)

%pre

%post
# SME 6 comes with a 'left panel cache' to improve the server panel display speed 
# But I don't find a nice way to update this cache
# So i choose to do this update here.
if [ -x /etc/e-smith/events/actions/navigation-conf ]
then
	echo "Rebuilding Web Server Manager Left Panel Cache ... Can take up to a minute."
	/etc/e-smith/events/actions/navigation-conf >/dev/null 2>&1
	echo "Done."
fi
echo "Installation finished."

%preun

%postun

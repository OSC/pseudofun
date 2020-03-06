# Disable debuginfo as it causes issues with bundled gems that build libraries
%global debug_package %{nil}
%global repo_name pseudofun
%global app_name pseudofun
%define ondemand_gems_ver %(rpm --qf "%%{version}" -q ondemand-gems)
%global gem_home %{scl_ondemand_gem_home}/apps/%{app_name}

%{!?package_release: %define package_release 1}
%{!?git_tag: %define git_tag v%{package_version}}
%define git_tag_minus_v %(echo %{git_tag} | sed -r 's/^v//')

%define __brp_mangle_shebangs /bin/true

# Work around issue with EL6 builds
# https://stackoverflow.com/a/48801417
%if 0%{?rhel} < 7
%define __strip /opt/rh/devtoolset-6/root/usr/bin/strip
%endif

Name:     ondemand-%{app_name}
Version:  %{package_version}
Release:  %{package_release}%{?dist}
Summary:  Pseudogene Functional Network

Group:    System Environment/Daemons
License:  MIT
URL:      https://github.com/OSC/%{repo_name}
Source0:  https://github.com/OSC/%{repo_name}/archive/%{git_tag}.tar.gz

BuildRequires:  sqlite-devel curl make
BuildRequires:  ondemand-runtime
BuildRequires:  ondemand-ruby
BuildRequires:  ondemand-nodejs
BuildRequires:  ondemand-scldevel
BuildRequires:  ondemand-gems
Requires:       ondemand
Requires:       ondemand-gems-%{ondemand_gems_ver}

# Disable automatic dependencies as it causes issues with bundled gems and
# node.js packages used in the apps
AutoReqProv: no

%description
Pseudogene Functional Network is a computational tool for studying potential
functions of pseudogenes in the context of evolution and diseases, developed by
the Zhang Lab of Computational Genomics and Proteomics at OSU BMI.

%prep
%setup -q -n %{repo_name}-%{git_tag_minus_v}


%build
scl enable ondemand - << \EOS
export GEM_HOME=$(pwd)/gems-build
export GEM_PATH=$(pwd)/gems-build:$GEM_PATH
export PASSENGER_APP_ENV=production
bin/setup
EOS


%install
%__mkdir_p %{buildroot}%{gem_home}
%__mv ./gems-build/* %{buildroot}%{gem_home}/
%__rm_rf ./gems-build

%__rm        ./log/production.log
%__mkdir_p   %{buildroot}%{_localstatedir}/www/ood/apps/sys/%{app_name}
%__cp -a ./. %{buildroot}%{_localstatedir}/www/ood/apps/sys/%{app_name}/
%__mkdir_p   %{buildroot}%{_localstatedir}/www/ood/apps/sys/%{app_name}/tmp
touch        %{buildroot}%{_localstatedir}/www/ood/apps/sys/%{app_name}/tmp/restart.txt
echo v%{version} > %{buildroot}%{_localstatedir}/www/ood/apps/sys/%{app_name}/VERSION

%__mkdir_p   %{buildroot}%{_sharedstatedir}/ondemand-nginx/config/apps/sys
touch        %{buildroot}%{_sharedstatedir}/ondemand-nginx/config/apps/sys/%{app_name}.conf


%post
# Install (not upgrade)
if [ $1 -eq 1 ]; then
  # This NGINX app config needs to exist before it can be rebuilt
  touch %{_sharedstatedir}/ondemand-nginx/config/apps/sys/%{app_name}.conf

  # Rebuild NGINX app config and restart PUNs w/ no active connections
  /opt/ood/nginx_stage/sbin/update_nginx_stage &>/dev/null || :
fi


%postun
# Uninstall (not upgrade)
if [[ $1 -eq 0 ]]; then
  # On uninstallation restart PUNs w/ no active connections
  /opt/ood/nginx_stage/sbin/update_nginx_stage &>/dev/null || :
fi


%posttrans
# Restart app in case PUN wasn't restarted
touch %{_localstatedir}/www/ood/apps/sys/%{app_name}/tmp/restart.txt


%files
%defattr(-,root,root)
%{gem_home}
%{_localstatedir}/www/ood/apps/sys/%{app_name}
%{_localstatedir}/www/ood/apps/sys/%{app_name}/manifest.yml
%ghost %{_localstatedir}/www/ood/apps/sys/%{app_name}/tmp/restart.txt
%ghost %{_sharedstatedir}/ondemand-nginx/config/apps/sys/%{app_name}.conf

%changelog
* Sun Feb 03 2019 Trey Dockendorf <tdockendorf@osc.edu> 0.2.1-3
- Update passenger apps to use new /var/lib/ondemand-nginx paths and new
  ondemand SCL for ondemand 1.5 (tdockendorf@osc.edu)

* Wed Oct 24 2018 Morgan Rodgers <mrodgers@osc.edu> 0.2.1-2
- Update pseudofun dependencies (mrodgers@osc.edu)

* Wed Jul 18 2018 Trey Dockendorf <tdockendorf@osc.edu> 0.2.0-2
- Remove production.log (tdockendorf@osc.edu)

* Tue May 29 2018 Jeremy Nicklas <jnicklas@osc.edu> 0.2.0-1
- Bump pseudofun to 0.2.0 (jnicklas@osc.edu)

* Thu May 24 2018 Jeremy Nicklas <jnicklas@osc.edu> 0.1.0-1
- new package built with tito


#
# Cookbook Name:: upstart
# Definition:: upstart_service
#
# Copyright (C) 2012 Felipe Gonçalves Coury
# 
# All rights reserved - Do Not Redistribute
#

default_attributes = {
  :only_if => false,
  :owner => "root",
  :group => "root",
  :process_name => nil,
  :processes => nil,
  :command => nil,
  :scale => 1,
  :path => nil
}

define :upstart_service, default_attributes do
  def add_process(init_dir, params, process_name, command)
    template "#{init_dir}/#{params[:name]}-#{process_name}.conf" do
      owner params[:owner]
      group params[:group]
      mode 0644
      source "main-service.conf.erb"
      variables params.merge(:command => command, :process_name => process_name)
      cookbook params[:cookbook] || "upstart"
    end

    1.upto(params[:scale].to_i) do |n|
      template "#{init_dir}/#{params[:name]}-#{process_name}-#{n}.conf" do
        owner params[:owner]
        group params[:group]
        mode 0644
        source "main-service-1.conf.erb"
        variables params.merge(:command => command, :process_name => process_name)
        cookbook params[:cookbook] || "upstart"
      end
    end
  end

  init_dir  = "/etc/init"
  main_conf = "#{params[:name]}.conf"
  log_dir   = (params[:log_dir] ||= "/var/log")

  directory "#{log_dir}" do
    owner params[:owner]
    group params[:group]
    mode 0755
    action :create
  end

  template "#{init_dir}/#{main_conf}" do
    owner params[:owner]
    group params[:group]
    mode 0644
    source "main.conf.erb"
    variables params
    cookbook params[:cookbook] || "upstart"
  end

  if procs = params[:processes]
    new_params = params.dup
    procs.each_pair do |process_name, command|
      add_process(init_dir, new_params, process_name, command)
    end
  else
    add_process(init_dir, params, params[:process_name], params[:command])
  end

  service params[:name] do
    provider Chef::Provider::Service::Upstart
    supports :restart => true, :status => true

    # start_command "start #{params[:name]}"
    # stop_command "stop #{params[:name]}"
    # restart_command "restart #{params[:name]} 2>/dev/null || start #{params[:name]}"
    # status_command "status #{params[:name]}"

    action :nothing
  end
end
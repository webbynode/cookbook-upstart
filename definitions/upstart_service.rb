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
  init_dir  = "/etc/init"
  main_conf = "#{params[:name]}.conf"

  params[:log_dir] ||= "/var/log"

  directory "#{log_dir}" do
    owner params[:owner]
    group params[:group]
    mode 0755
    action :create
  end

  template "#{init_dir}/#{main_conf}" do
    owner params[:owner]
    group params[:group]
    mode 0755
    source "main.conf.erb"
    variables params
    cookbook params[:cookbook] if params[:cookbook]
  end

  if procs = params[:processes]
    new_params = params.clone
    procs.each_pair do |process_name, command|
      new_params[:process_name] = process_name
      new_params[:command] = command

      add_process(init_dir, new_params)
    end
  else
    add_process(init_dir, params)
  end
end

def add_process(init_dir, params)
  template "#{init_dir}/#{params[:name]}-#{params[:process_name]}.conf" do
    owner params[:owner]
    group params[:group]
    mode 0755
    source "main-service.conf.erb"
    variables params
    cookbook params[:cookbook] if params[:cookbook]
  end

  [1..params[:scale].to_i].each do |n|
    template "#{init_dir}/#{params[:name]}-#{params[:process_name]}-#{n}.conf" do
      owner params[:owner]
      group params[:group]
      mode 0755
      source "main-service-1.conf.erb"
      variables params
      cookbook params[:cookbook] if params[:cookbook]
    end
  end
end

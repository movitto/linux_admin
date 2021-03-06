require 'spec_helper'
require 'stringio'

describe LinuxAdmin::FSTab do
  before do
    # Reset the singleton so subsequent tests get a new instance
    Singleton.send :__init__, LinuxAdmin::FSTab
  end

  it "newline, single spaces, tab" do
    fstab = <<eos

  
	
eos
    File.should_receive(:read).with('/etc/fstab').and_return(fstab)
    LinuxAdmin::FSTab.instance.entries.size.should == 0
  end

  it "creates FSTabEntry for each line in fstab" do
    fstab = <<eos
# Comment, indented comment, comment with device information
  # /dev/sda1 / ext4  defaults  1 1
# /dev/sda1 / ext4  defaults  1 1
/dev/sda1 / ext4  defaults  1 1
/dev/sda2 swap  swap  defaults  0 0
eos
    File.should_receive(:read).with('/etc/fstab').and_return(fstab)
    entries = LinuxAdmin::FSTab.instance.entries
    entries.size.should == 2

    entries[0].device.should == '/dev/sda1'
    entries[0].mount_point.should == '/'
    entries[0].fs_type.should == 'ext4'
    entries[0].mount_options.should == 'defaults'
    entries[0].dumpable.should == 1
    entries[0].fsck_order.should == 1

    entries[1].device.should == '/dev/sda2'
    entries[1].mount_point.should == 'swap'
    entries[1].fs_type.should == 'swap'
    entries[1].mount_options.should == 'defaults'
    entries[1].dumpable.should == 0
    entries[1].fsck_order.should == 0
  end

  describe "#write!" do
    it "writes entries to /etc/fstab" do
      # maually set fstab
      entry = LinuxAdmin::FSTabEntry.new
      entry.device        = '/dev/sda1'
      entry.mount_point   = '/'
      entry.fs_type       = 'ext4'
      entry.mount_options = 'defaults'
      entry.dumpable      = 1
      entry.fsck_order    = 1
      LinuxAdmin::FSTab.any_instance.stub(:refresh) # don't read /etc/fstab
      LinuxAdmin::FSTab.instance.entries = [entry]

      File.should_receive(:write).with('/etc/fstab', "/dev/sda1 / ext4 defaults 1 1\n")
      LinuxAdmin::FSTab.instance.write!
    end
  end
end

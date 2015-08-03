require "vagrant-unison/config"

describe VagrantPlugins::Unison::Config do
  let(:instance) { described_class.new }

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("host_folder")     { should be_nil }
    its("guest_folder")    { should be_nil }
    its("ignore")          { should be_nil }
    its("follow")          { should be_nil }
  end

  describe "overriding defaults" do
    # I typically don't meta-program in tests, but this is a very
    # simple boilerplate test, so I cut corners here. It just sets
    # each of these attributes to "foo" in isolation, and reads the value
    # and asserts the proper result comes back out.
    [:host_folder, :guest_folder].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end
end

RSpec.describe StressStats do
    it "has a version number" do
        expect(StressStats::VERSION).not_to be nil
    end

    RSpec.describe "RemoteTest" do


        it "creates an ssh session" do
            s = StressStats::RemoteTest.new('test-vm')
            expect().to eq(true)
        end
    end
end

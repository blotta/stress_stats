require 'time'

require 'net/ssh'
require 'colorize'

module StressStats
    class RemoteTest
        def initialize(
            remote_host: 'localhost',
            local_cmd: 'for i in `seq 1 5`; do echo $i; sleep 1; done',
            setup: [],
            sar_stats: '-A', sar_outfile: 'sar-results', sar_freq: 2, sar_count: nil
        )

            @remote_host = remote_host
            @local_cmd = local_cmd
            @setup = setup
            @test_done = false # Thread looks at this to stop
            @t1_rmt, @t2_rmt = nil, nil # Time on remote host just before and after test
            @sar = {
                :stats => sar_stats,
                :binfile => sar_outfile,
                :freq => sar_freq,
                :count => sar_count
            }

            @sar_ch = nil

            begin
                @ssh_session = Net::SSH.start(@remote_host)
            rescue SocketError => e
                puts "Couldn't start ssh session to '#{@remote_host}'"
                puts "Returned: #{e}"
                exit 2
            end

            self.check_rmt

            puts self
        end

        def to_s
            s = [ "host: #{@remote_host}" ]
            s << "setup: #{@setup}" unless @setup.empty?
            s << "Sar: #{self.sar_cmd}"
            s << "Sadf: #{self.sadf_cmd}" unless @t1.nil?
            return s.join(" ; ")
        end

        def check_rmt
            # Checks if connection can be established and that the sar command exists
            _, err = self.get_output_cmd("which sar")
            unless err.nil? or err.empty?
                puts "Sar command not found on remote host. Please install the 'sysstat' package"
                puts "Err: #{err}"
                exit 2
            end
        end

        def run_rmt_cmd(cmd)
            return @ssh_session.exec!(cmd)
        end

        def get_output_cmd(cmd)
            out = ''
            err = ''
            @ssh_session.exec! cmd do |ch, stream, data|
                out << data if stream == :stdout
                err << data if stream == :stderr
            end
            return out, err
        end

        def setup_rmt
            if @setup.empty?
                puts 'Nothing to setup'.colorize(:yellow).bold
                return
            else
                puts 'Setting up remote host'.colorize(:light_blue)
            end

            @setup.each do |cmd|
                puts "Running '#{cmd}' on remote host"
                self.run_rmt_cmd(cmd)
            end
            puts 'Setup finished'
        end

        def sar_cmd
            [ 'sar', @sar[:stats], '-o', @sar[:binfile], @sar[:freq].to_s,
              @sar[:count].to_s ].reject{|s| s.empty?}.join(' ')
        end

        def sadf_cmd(since: nil, endtime: nil, sar_stats: @sar[:stats])
            cmd = [ 'sadf', '-j' ] # basecmd, json return

            cmd << '-s' << Time.parse(since).strftime("%H:%M:%S") if not since.nil?

            cmd << '-e' << Time.parse(endtime).strftime("%H:%M:%S") if not endtime.nil?

            cmd << '--' << sar_stats

            cmd << @sar[:binfile]

            cmd.reject{|s| s.empty?}.join(' ')
        end

        def run_sar
            puts "Running Sar on remote host".colorize(:magenta).bold

            @sar_ch = @ssh_session.open_channel do |ch|
                ch.exec(self.sar_cmd) do |chan, success|
                    raise "Couldn't run sar command" unless success
                    chan.on_data do |c, data|
                        if @test_done
                            c.close
                        end
                    end
                    chan.on_close { puts "Sar command stopped".colorize(:magenta) }
                end
            end if @sar_ch.nil?

            # wait here while sar is running
            @sar_ch.wait

            # reassign it to nil when sar command is done
            @sar_ch = nil

        end

        def run_local_cmd
            puts "Running '#{@local_cmd}' locally"
            system(@local_cmd) # needs to be blocking
            @test_done = true
        end

        def run_test_with_sar

            # Get time of remote system, before session is busy running sar
            self.start_time= run_rmt_cmd('date').strip
            puts "Running Test at #{@t1_rmt} on remote host".green.bold.blink

            # Starts sar ssh session on another thread and runs the stress test locally
            sar_t = Thread.new{ self.run_sar }

            # Run test locally
            self.run_local_cmd

            # Wait for sar thread to finish
            sar_t.join

            # Get time of remote system after session is busy running sar
            self.end_time= run_rmt_cmd('date').strip
            puts "Test finished at #{@t2_rmt} on remote host"

        end

        def start_time=(t1) @t1_rmt = t1 end
        def end_time=(t2) @t2_rmt = t2 end
        def start_time() @t1_rmt end
        def end_time() @t2_rmt end

        def benchmk
            self.setup_rmt
            self.run_test_with_sar
        end

        def fetch_results()
            cmd = sadf_cmd(since: @t1_rmt, endtime: @t2_rmt)
            puts "Running command '#{cmd}' on remote host"
            out, _ = get_output_cmd(cmd)
            # puts "Got #{out} from remote host"
            unless out.nil? or out.empty?
                return out
            else
                return nil
            end
        end

    end # RemoteTest class
end

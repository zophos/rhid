#
# usbio.rb -- wrapper for Morphy Planning USB-IO family
#
# NISHI Takao <zophos@koka-in.org>
#
require 'rhid/win32'
require 'thread'

class UsbIo
    ON=Lo=0
    OFF=Hi=1
    
    class Port
        def initialize(bit_num=8,init_val=Hi)
            @bits=Array.new(bit_num)
            self.fill(init_val)
        end
        def fill(n)
            raise ArgumentError if(n!=Lo&&n!=Hi)
            @bits.map!{|x| x=n }
        end
        def [](x)
            @bits[x]
        end
        def []=(x,n)
            x=x.to_i
            raise ArgumentError if((n!=Lo&&n!=Hi)||(x>=@bits.size))
            @bits[x]=n
        end
        def toggle(x)
            raise ArgumentError if(x>=@bits.size)
            @bits[x]^=Hi
        end

        def to_s
            [@bits.join('')].pack('b*')
        end
        def to_i
            self.to_s.unpack('C*')[0]
        end
        def to_a
            @bits.dup
        end

        def from_i(val)
            @bits=[val.to_i].pack('C*').unpack('b*')[0].split(//).map{|x|
                x.to_i
            }[0...@bits.size]
        end
    end

    def initialize(vendor_id=0x12ed,product_id=0x1003)
        @port=[Port.new(8),Port.new(4)].freeze
        @mutex=Mutex.new
        @seq=1
        self.open(vendor_id,product_id)
    end
    attr_reader :port

    def open(vendor_id=0x12ed,product_id=0x1003)
        @connector=RHid.open_by_id(vendor_id,product_id) unless @connector
        @port.each{|p| p.fill(OFF) }
        self.write
        self
    end
    def close
        @connector.close if @connector
        @connector=nil
    end

    def write(port=nil)
        cmd=nil
        case port
        when nil
            return self.write(0)+self.write(1)
        when 0
            cmd=0x01
        when 1
            cmd=0x02
        else
            raise ArgumentError
        end

        ret=nil
        @mutex.synchronize{
            ret=@connector.write(_build_request(cmd,@port[port]))
        }

        ret
    end

    def read(port=nil)
        cmd=nil
        case port
        when nil
            return self.read(0)+self.read(1)
        when 0
            cmd=0x03
        when 1
            cmd=0x04
        else
            raise ArgumentError
        end

        val=nil
        @mutex.synchronize{
            @connector.write(_build_request(cmd,0xff))

            #
            # compare command and sequence number between the query with
            # the reply to discard pre-fetched replies.
            #
            begin
                (rcmd,val,oid,seq)=_parse_reply(@connector.read)
                raise RHid::DoRetryError if((rcmd!=cmd)||
                                                (oid!=self.__id__)||
                                                (seq!=@seq))
            rescue RHid::DoRetryError
                retry
            end
        }

        @port[port].from_i(val)
    end

    private
    def _build_request(cmd,val)
        #
        # set sequence number to the request message
        #
        @seq=[@seq+1].pack('n').unpack('n')[0]
        [cmd.to_i,val.to_i,self.__id__,@seq].pack('nCNn')
    end

    def _parse_reply(rpl)
        rpl.unpack('nCNn')
    end
end

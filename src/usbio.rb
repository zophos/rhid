#
# usbio.rb -- wrapper for Morphy Planning USB-IO family
#
# NISHI Takao <zophos@koka-in.org>
#
require 'rhid/win32'

class UsbIo
    ON=0
    OFF=1
    Lo=0
    Hi=1
    
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
            raise ArgumentError if(n!=Lo&&n!=Hi)
            raise ArgumentError if(x>=@bits.size)
            @bits[x]=n
        end
        def toggle(x)
            raise ArgumentError if(x>=@bits.size)
            @bits[x]^=OFF
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
            @bits=
                [val.to_i].pack('C*').unpack('b*')[0].split(//)[
                0...@bits.size
            ].map{|x|
                x.to_i
            }
        end
    end

    def initialize(vendor_id=0x12ed,product_id=0x1003)
        @seq=1
        @port=[Port.new(8),Port.new(4)]
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
        case port
        when nil
            @connector.write("\x0\x1"+@port[0].to_s)+
                @connector.write("\x0\x2"+@port[1].to_s)
        when 0
            @connector.write("\x0\x1"+@port[0].to_s)
        when 1
            @connector.write("\x0\x2"+@port[1].to_s)
        else
            raise ArgumentError
        end
    end

    def read(port=nil)
        cmd=nil
        case port
        when nil
            return self.read(0)+self.read(1)
        when 0
            scmd=3
        when 1
            scmd=4
        else
            raise ArgumentError
        end

        #
        # set sequence number to the query
        #
        @seq=[@seq+1].pack('n').unpack('n')[0]
        @connector.write([scmd].pack('n')+
                             "\xff"+
                             [self.__id__].pack('N')+
                             [@seq].pack('n'))

        #
        # compare command and sequence number between the query with
        # the reply to discard the driver's pre-fetched reply.
        #
        begin
            (rcmd,val,id,seq)=@connector.read.unpack('nCNn')
            raise RHid::DoRetryError if((rcmd!=scmd)||
                                            (id!=self.__id__)||
                                            (seq!=@seq))
        rescue RHid::DoRetryError
            retry
        end

        @port[port].from_i(val)
    end

    def exec(port,bit,val)
        @port[port][bit]=val
        self.write(port)
    end
end

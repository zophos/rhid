#
#
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
    end

    def initialize(vendor_id=0x12ed,product_id=0x1003)
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
        if(port.nil?)
            @connector.write("\0"+"\x1"+@port[0].to_s)
            @connector.write("\0"+"\x2"+@port[1].to_s)
        elsif(port==0)
            @connector.write("\0"+"\x1"+@port[0].to_s)
        elsif(port==1)
            @connector.write("\0"+"\x2"+@port[1].to_s)
        else
            raise ArgumentError if(port!=0&&port!=1)
        end
    end

    def exec(port,bit,val)
        @port[port][bit]=val
        self.write(port)
    end
end

#
#
#
require 'usbio'

class Joint
    def initialize(usbio,port,nornaml_bit,reverse_bit)
        @usbio=usbio
        @port=port
        @normal_bit=nornaml_bit
        @reverse_bit=reverse_bit
    end
    def normal(exec=false)
        @usbio.port[@port][@normal_bit]=UsbIo::ON
        @usbio.port[@port][@reverse_bit]=UsbIo::OFF
        @usbio.write(@port) if exec
    end
    def reverse(exec=false)
        @usbio.port[@port][@normal_bit]=UsbIo::OFF
        @usbio.port[@port][@reverse_bit]=UsbIo::ON
        @usbio.write(@port) if exec
    end
    def toggle(exec=false)
        @usbio.port[@port].toggle(@normal_bit)
        @usbio.port[@port].toggle(@reverse_bit)
        @usbio.write(@port) if exec
    end
    def stop(exec=false)
        @usbio.port[@port][@normal_bit]=UsbIo::OFF
        @usbio.port[@port][@reverse_bit]=UsbIo::OFF
        @usbio.write(@port) if exec
    end
    def exec
        @usbio.write(@port)
    end
end

class MR999
    WAIST=0
    SHOULDER=1
    ELBOW=2
    WRITE=3
    FINGER=4

    def initialize(vendor_id=0x12ed,product_id=0x1003)
        @usbio=UsbIo.new(vendor_id,product_id)

        @joint=[@waist=Joint.new(@usbio,0,5,4),
            @shoulder=Joint.new(@usbio,0,6,7),
            @elbow=Joint.new(@usbio,0,3,2),
            @wrist=Joint.new(@usbio,1,1,0),
            @finger=Joint.new(@usbio,0,0,1)]
    end
    attr_reader :waist,:shoulder,:elbow,:wrist,:finger

    def exec
        @usbio.write
    end

    def stop
        @joint.each{|j| j.stop(false) }
        @usbio.write
    end

    def init
        self.stop

        $stderr<<"waist"
        self.waist.normal(1)
        STDIN.getc
        self.stop
        
        $stderr<<"shoulder"
        self.shoulder.normal(1)
        STDIN.getc
        self.stop
        
        $stderr<<"elbow"
        self.elbow.reverse(1)
        STDIN.getc
        self.stop
        
        $stderr<<"wrist"
        self.wrist.normal(1)
        STDIN.getc
        self.stop
        
        $stderr<<"finger"
        self.finger.normal(1)
        STDIN.getc
        self.stop
        $stderr<<"\n"
    end

    def grip
        self.waist.reverse(1)
        sleep(13)
        self.wrist.reverse(1)
        sleep(5)
        self.stop

        self.elbow.normal(1)
        sleep(15)
        self.shoulder.reverse(1)
        sleep(12)
        self.finger.reverse(1)
        sleep(3)
        self.stop

        $stderr<<"Hit Enter to Continue..."
        STDIN.getc
        self.finger.normal(1)
        sleep(3)
        self.stop
        self.shoulder.normal
        self.elbow.reverse
        self.exec
        sleep(5)
        self.stop
    end

    def shake
        self.stop


        self.waist.normal
        self.wrist.normal
        self.exec
        sleep(2)
        self.wrist.toggle(1)
        sleep(2)

        while(true)
            self.waist.toggle(1)
            self.wrist.toggle(1)
            sleep(2)
            self.wrist.toggle(1)
            sleep(2)
        end
        self.stop
    end
end

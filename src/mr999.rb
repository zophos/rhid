#
# mr999.rb --  ELEKIT MR-999 and IF-100 accesse library
#
# NISHI Takao <zophos@koka-in.org>
#
require 'usbio'


class MR999
    WAIST=0
    SHOULDER=1
    ELBOW=2
    WRITE=3
    FINGER=4

    ######################################################################
    #
    #
    #
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
            self.exec if exec
        end
        def reverse(exec=false)
            @usbio.port[@port][@normal_bit]=UsbIo::OFF
            @usbio.port[@port][@reverse_bit]=UsbIo::ON
            self.exec if exec
        end
        def toggle(exec=false)
            @usbio.port[@port].toggle(@normal_bit)
            @usbio.port[@port].toggle(@reverse_bit)
            self.exec if exec
        end
        def stop(exec=false)
            @usbio.port[@port][@normal_bit]=UsbIo::OFF
            @usbio.port[@port][@reverse_bit]=UsbIo::OFF
            self.exec if exec
        end
        def exec
            @usbio.write(@port)
        end
    end
    #
    # end of MR999::Joint
    #

    def initialize(vendor_id=0x12ed,product_id=0x1003)
        @usbio=UsbIo.new(vendor_id,product_id)

        @joint=[@waist=Joint.new(@usbio,0,5,4),
            @shoulder=Joint.new(@usbio,0,6,7),
            @elbow=Joint.new(@usbio,0,3,2),
            @wrist=Joint.new(@usbio,1,1,0),
            @finger=Joint.new(@usbio,0,0,1)].freeze
    end
    attr_reader :waist,:shoulder,:elbow,:wrist,:finger

    def exec
        @usbio.write
    end

    def stop
        @joint.each{|j| j.stop(false) }
        @usbio.write
    end

    #
    # set initial position
    #
    def init
        self.stop

        $stderr<<"shoulder"
        self.shoulder.normal(true)
        STDIN.getc
        self.stop
        
        $stderr<<"elbow"
        self.elbow.reverse(true)
        STDIN.getc
        self.stop
        
        $stderr<<"wrist"
        self.wrist.normal(true)
        STDIN.getc
        self.stop
        
        $stderr<<"finger"
        self.finger.normal(true)
        STDIN.getc
        self.stop

        $stderr<<"waist"
        self.waist.normal(true)
        STDIN.getc
        self.stop

        $stderr<<"\n"
        
        self
    end

    #
    # move from initial position to grasping position, and grasp something
    #
    # You MUST adjust each sleep length with your MR-999
    #
    def grasp
        self.stop

        #
        # rotate the wasit and the wrist
        #
        self.waist.reverse(true)
        sleep(14.5)
        self.wrist.reverse(true)
        sleep(5.5)
        self.stop

        #
        # extend the elbow and shoulder, and open the finger
        #
        self.elbow.normal(true)
        sleep(15)
        self.shoulder.reverse(true)
        sleep(12)
        self.finger.reverse(true)
        sleep(3)
        self.stop

        #
        # waki-waki
        #
        2.times{|i|
            self.finger.normal(true)
            sleep(0.5)
            self.finger.reverse(true)
            sleep(0.5)
        }
        self.stop


        $stderr<<"Hit Enter to Continue..."
        STDIN.getc

        
        #
        # close finger
        #
        self.finger.normal(true)
        sleep(3)
        self.stop

        #
        # shrink the elbow and the shoulder 
        #
        self.shoulder.normal
        self.elbow.reverse
        self.exec
        sleep(5)
        self.stop

        self
    end

    #
    # shake the grasping somthing (e.g, leek)
    #
    def shake
        self.stop

        self.waist.normal(true)
        self.wrist.normal(true)
        sleep(1.5)

        5.times{|i|
            self.waist.toggle(true)
            self.wrist.toggle(true)
            sleep(3)
        }
        self.stop

        self
    end
end

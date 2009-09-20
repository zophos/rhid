#
# rhid.rb -- HID class access library
#
# NISHI Takao <zophos@koka-in.org>
#
class RHid
    class DoRetryError<StandardError;end

    Capabilities=Struct.new(:usage,
                            :usagePage,
                            :inputReportByteLength,
                            :outputReportByteLength,
                            :featureReportByteLength,
                            :numberLinkCollectionNodes,
                            :numberInputButtonCaps,
                            :numberInputValueCaps,
                            :numberInputDataIndices,
                            :numberOutputButtonCaps,
                            :numberOutputValueCaps,
                            :numberOutputDataIndices,
                            :numberFeatureButtonCaps,
                            :numberFeatureValueCaps,
                            :numberFeatureDataIndices)

    def self.open_by_id(vendor_id,product_id,&block)
        self.new.open_by_id(vendor_id,product_id,&block)
    end

    def self.open_by_path(path,&block)
        self.new.open_by_id(path,&block)
    end

    def initialize
        @capabilities=nil
        super
    end

    def read
        super
    end

    def write(data)
        super
    end
    alias << write
end

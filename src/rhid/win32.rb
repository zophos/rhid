#
# rhid/win32.rb -- HID class access library for Win32API
#
# NISHI Takao <zophos@koka-in.org>
#
require 'rhid'

require 'dl/import'
require 'dl/struct'

class RHid
    module Win32

        ##################################################################
        #
        # API Declaring
        #
        module Api
            extend DL::Importable
            
            GENERIC_READ=[0x80000000].pack('L').unpack('l')[0]
            GENERIC_WRITE=[0x40000000].pack('L').unpack('l')[0]
            FILE_SHARE_READ=0x01
            FILE_SHARE_WRITE=0x02
            
            OPEN_EXISTING=3
            
            DIGCF_PRESENT=0x02
            DIGCF_DEVICEINTERFACE=0x10
            
            HidP_Input=0
            HidP_Output=1
            HidP_Feature=2
            
            
            dlload('kernel32.dll',
                   'hid.dll',
                   'setupapi.dll')
            
            GUID=
                struct([
                           'long  data1',
                           'short data2',
                           'short data3',
                           'char  data4[8]'
                       ])
            
            HIDD_ATTRIBUTES=
                struct([
                           'long cbSize',
                           'short vendorID',
                           'short productID',
                           'short versionNumber'
                       ])
            
            HIDP_CAPS=
                struct([
                           'short usage',
                           'short usagePage',
                           'short inputReportByteLength',
                           'short outputReportByteLength',
                           'short featureReportByteLength',
                           'short reserved[17]',
                           'short numberLinkCollectionNodes',
                           'short numberInputButtonCaps',
                           'short numberInputValueCaps',
                           'short numberInputDataIndices',
                           'short numberOutputButtonCaps',
                           'short numberOutputValueCaps',
                           'short numberOutputDataIndices',
                           'short numberFeatureButtonCaps',
                           'short numberFeatureValueCaps',
                           'short numberFeatureDataIndices'
                       ])
            
            HidP_Value_Caps=
                struct([
                           'short usagePage',
                           'char * reportID',
                           'long isAlias',
                           'short bitField',
                           'short linkCollection',
                           'short linkUsage',
                           'short linkUsagePage',
                           'long isRange',
                           'long isStringRange',
                           'long isDesignatorRange',
                           'long isAbsolute',
                           'long hasNull',
                           'char * reserved',
                           'short bitSize',
                           'short reportCount',
                           'short reserved2',
                           'short reserved3',
                           'short reserved4',
                           'short reserved5',
                           'short reserved6',
                           'long logicalMin',
                           'long logicalMax',
                           'long physicalMin',
                           'long physicalMax',
                           'short usageMin',
                           'short usageMax',
                           'short stringMin',
                           'short stringMax',
                           'short designatorMin',
                           'short designatorMax',
                           'short dataIndexMin',
                           'short dataIndexMax'
                       ])
            
            SP_DEVICE_INTERFACE_DATA=
                struct([
                           'long cbSize',
                           'long  interfaceClassGuid_Data1',
                           'short interfaceClassGuid_Data2',
                           'short interfaceClassGuid_Data3',
                           'char  interfaceClassGuid_Data4[8]',
                           'long flags',
                           'long reserved'
                       ])
            
            SP_DEVICE_INTERFACE_DETAIL_DATA=
                struct([
                           'long cbSize',
                           'char devicePath[1]'
                       ])
            
            SP_DEVINFO_DATA=
                struct([
                           'long cbSize',
                           'long  classGuid_Data1',
                           'short classGuid_Data2',
                           'short classGuid_Data3',
                           'char  classGuid_Data4[8]',
                           'long devInst',
                           'long reserved'
                       ])
            

            #
            # kernel32.dll
            #
            extern(<<_EOS_
long CreateFileA(char *,long,long,long *,long,long,long)
_EOS_
                   )

            extern(<<_EOS_
long CloseHandle(long)
_EOS_
                   )

            extern(<<_EOS_
long ReadFile(long,void *,long,long *,long)
_EOS_
                   )

            extern(<<_EOS_
long WriteFile(long,char *,long,long *,long)
_EOS_
                   )

            extern(<<_EOS_
long FormatMessageA(long,void *,long,long,char *,long,long)
_EOS_
                   )
            extern(<<_EOS_
long GetLastError()
_EOS_
                   )


            #
            # hid.dll
            #
            extern(<<_EOS_
long HidD_FreePreparsedData(long)
_EOS_
                   )

            extern(<<_EOS_
long HidD_GetAttributes(long,HIDD_ATTRIBUTES *)
_EOS_
                   )

            extern(<<_EOS_
long HidD_GetHidGuid(GUID *)
_EOS_
                   )

            extern(<<_EOS_
long HidD_GetPreparsedData(long,long *)
_EOS_
                   )

            extern(<<_EOS_
long HidP_GetCaps(long,HIDP_CAPS *)
_EOS_
                   )

            extern(<<_EOS_
long HidP_GetValueCaps(short,char *,short *,long)
_EOS_
                   )

            #
            # setupapi.dll
            #
            extern(<<_EOS_
long SetupDiCreateDeviceInfoList(GUID *,long)
_EOS_
                   )

            extern(<<_EOS_
long SetupDiDestroyDeviceInfoList(long)
_EOS_
                   )

            extern(<<_EOS_
long SetupDiEnumDeviceInterfaces(long,
    long,
    GUID *,
    long,
    SP_DEVICE_INTERFACE_DATA *)
_EOS_
                   )

            extern(<<_EOS_
long SetupDiGetClassDevsA(GUID *,void *,long,long)
_EOS_
                   )

            extern(<<_EOS_
long SetupDiGetDeviceInterfaceDetailA(long,
    SP_DEVICE_INTERFACE_DATA *,
    SP_DEVICE_INTERFACE_DETAIL_DATA *,
    long,
    long *,
    long)
_EOS_
                   )
        end
        #
        # end of RHid::Win32::Api
        #
    

        ##################################################################
        #
        #
        #
        def initialize
            @path=nil
            @handle=nil
        end

        ##################################################################
        #
        #
        #
        def open_by_id(vendor_id,product_id,&block)
            raise(IOError,'Already opened') if @handle

            guid=Api::GUID.malloc
            Api.hidD_GetHidGuid(guid)
            dis=Api.setupDiGetClassDevsA(guid,nil,0,
                                         Api::DIGCF_PRESENT|
                                             Api::DIGCF_DEVICEINTERFACE)

            did=Api::SP_DEVICE_INTERFACE_DATA.malloc
            did.cbSize=Api::SP_DEVICE_INTERFACE_DATA.size
            
            sz=DL.strdup("\0"*DL::sizeof('L'))
            
            hidda=Api::HIDD_ATTRIBUTES.malloc
            hidda.cbSize=hidda.size
            
            i=0
            begin
                raise Errno::ENOENT if Api.setupDiEnumDeviceInterfaces(dis,
                                                                       0,
                                                                       guid,
                                                                       i,
                                                                       did
                                                                       )==0
                ret=
                    Api.setupDiGetDeviceInterfaceDetailA(dis,did,nil,0,sz,0)
                s=sz.to_a('L')[0]
                didd=Api::SP_DEVICE_INTERFACE_DETAIL_DATA.malloc(s)
                didd.cbSize=5
                
                ret=
                    Api.setupDiGetDeviceInterfaceDetailA(dis,did,didd,s,nil,0)
                raise DoRetryError if ret==0
                
                @path=didd.to_ptr[4,s-didd.cbSize]
                @handle=Api.createFileA(@path,
                                        Api::GENERIC_READ|
                                            Api::GENERIC_WRITE,
                                            Api::FILE_SHARE_READ|
                                            Api::FILE_SHARE_WRITE,
                                        nil,
                                        Api::OPEN_EXISTING,
                                        0,0)
                raise DoRetryError if @handle==-1
                
                ret=Api.hidD_GetAttributes(@handle,hidda)
                
                raise DoRetryError if (ret==0 ||
                                           hidda.vendorID!=vendor_id ||
                                           hidda.productID!=product_id)
            rescue DoRetryError
                Api.closeHandle(@handle) if (@handle&&@handle!=-1)
                @handle=nil
                @path=nil
                i+=1
                retry
            rescue Errno::ENOENT
                @handle=nil
                @path=nil
                raise
            ensure
                Api.setupDiDestroyDeviceInfoList(dis)
            end
            
            ObjectSpace.define_finalizer(self,RHid.finalize(@handle))
            if(block)
                yield(self)
                self.close
            else
                self
            end
        end
        #
        # end of open_by_id
        #


        ##################################################################
        #
        #
        #
        def open_by_path(path,&block)
            raise(IOError,'Already opened') if @handle

            @handle=Api.createFileA(path,
                                    Api::GENERIC_READ|
                                        Api::GENERIC_WRITE,
                                    Api::FILE_SHARE_READ|
                                        Api::FILE_SHARE_WRITE,
                                    nil,
                                    Api::OPEN_EXISTING,
                                    0,0)
            if(@handle==-1)
                @hadnle=nil
                raise Errno::ENOENT
            end
            
            @path=path
            ObjectSpace.define_finalizer(self,RHid.finalize(@handle))
            if(block)
                yield(self)
                self.close
            else
                self
            end
        end
        #
        # end of open_by_path
        #

        ##################################################################
        #
        #
        #
        def close
            ObjectSpace.undefine_finalizer(self)

            Api.closeHandle(@handle) if @handle
            @capabilities=nil
            @handle=nil
        end
        #
        # end of close
        #


        ##################################################################
        #
        #
        #
        def capabilities
            raise IOError unless @handle
            return @capabilities if @capabilities

            preparsed_data=DL.strdup("\0"*DL::sizeof('L'))
            if(Api.hidD_GetPreparsedData(@handle,preparsed_data)==1)
                caps=Api::HIDP_CAPS.malloc
                unless(Api.hidP_GetCaps(preparsed_data.to_a('L')[0],caps)==0)
                    @capabilities=Capabilities.new(caps.usage,
                                                   caps.usagePage,
                                                   caps.inputReportByteLength,
                                                   caps.outputReportByteLength,
                                                   caps.featureReportByteLength,
                                                   caps.numberLinkCollectionNodes,
                                                   caps.numberInputButtonCaps,
                                                   caps.numberInputValueCaps,
                                                   caps.numberInputDataIndices,
                                                   caps.numberOutputButtonCaps,
                                                   caps.numberOutputValueCaps,
                                                   caps.numberOutputDataIndices,
                                                   caps.numberFeatureButtonCaps,
                                                   caps.numberFeatureValueCaps,
                                                   caps.numberFeatureDataIndices)

                end

                #
                # fixme: implement Api.hidP_GetValueCaps 
                #

                Api::hidD_FreePreparsedData(preparsed_data.to_a('L')[0])
            end
            

            @capabilities
        end
        #
        # end of capabilities
        #


        ##################################################################
        #
        #
        #
        def read
            self.capabilities
            raise IOError unless @capabilities

            buf=DL.strdup("\0"*@capabilities.inputReportByteLength)
            sz=DL.strdup("\0"*DL::sizeof('L'))
            ret=Api.readFile(@handle,
                             buf,
                             @capabilities.inputReportByteLength,
                             sz,0)

            raise(IOError,"#{Api.getLastError}") if ret==0

            buf.to_s(sz.to_a('L')[0])
        end
        #
        # end of read
        #

        ##################################################################
        #
        #
        #
        def write(data)
            self.capabilities
            raise IOError unless @capabilities

            data=data.to_s
            sz=data.unpack('C*').size
            if(sz<@capabilities.outputReportByteLength)
                data+="\xff"*(@capabilities.outputReportByteLength-sz)
            end

            sz=DL.strdup("\0"*DL::sizeof('L'))
            ret=Api.writeFile(@handle,
                              data,
                              @capabilities.outputReportByteLength,
                              sz,0)
            raise(IOError,"#{Api.getLastError}") if ret==0

            sz.to_a('L')[0]
        end
        #
        # end of write
        #
    end
    #
    # end of RHid::Win32
    #

    include Win32

    def RHid.finalize(handle)
        Proc.new{
            Api.closeHandle(handle)  if (handle && handle!=-1)
        }
    end

end

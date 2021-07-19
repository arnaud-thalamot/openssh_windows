########################################################################################################################
#                                                                                                                      #
#                                  OpenSSH Cookbook           											               #
#                                                                                                                      #
#   Language            : Chef/Ruby                                                                                    #
#   Date                : 11/28/2017                                                                                   #
#   Date Last Update    : 11/28/2017                                                                                   #
#   Version             : 1.0                                                                                          #
#   Author              : Arnaud Thalamot                                                                              #
#                                                                                                                      #
########################################################################################################################

#  Install OpenSSH
ibm_openssh_win_openssh 'install_openssh' do
    action [:install]
end
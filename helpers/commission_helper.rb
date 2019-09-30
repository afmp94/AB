module CommissionHelper

  def commission_threshold_for_broker_fee_alternative_split(fee, alternative_split)
    if fee && alternative_split && fee > 0 && alternative_split > 0
      num_to_currency(fee / (alternative_split / 100))
    else
      "-"
    end
  end

end

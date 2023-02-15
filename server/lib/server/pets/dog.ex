defmodule Server.Pets.Dog do
  use Server.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          breed: String.t(),
          description: String.t(),
          image_url: String.t()
        }

  @autogenerated_fields ~w(id uid inserted_at updated_at)a

  @create_required_fields ~w(breed description image_url)a

  schema "dogs" do
    field :uid, Ecto.UUID, read_after_writes: true
    field :breed, :string
    field :description, :string
    field :image_url, :string

    timestamps()
  end

  @spec create_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def create_changeset(dog, attrs) do
    dog
    |> cast(attrs, all_fields() -- @autogenerated_fields)
    |> validate_required(@create_required_fields)
    |> validate_image_url()
    |> downcase_breed()
    |> unique_constraint(:breed, message: "Breed is already taken")
  end

  @spec all_fields :: list(atom())
  defp all_fields, do: __MODULE__.__schema__(:fields)

  @spec downcase_breed(Changeset.t()) :: Changeset.t()
  defp downcase_breed(changeset) do
    update_change(changeset, :breed, &String.downcase/1)
  end

  @spec validate_image_url(Changeset.t()) :: Changeset.t()
  defp validate_image_url(changeset) do
    with image_url when not is_nil(image_url) <- get_change(changeset, :image_url),
         false <- url?(image_url) do
      add_error(changeset, :image_url, "invalid value", validation: :value)
    else
      _ -> changeset
    end
  end

  @spec url?(String.t()) :: boolean()
  defp url?(url) do
    uri = URI.parse(url)
    # https://stackoverflow.com/questions/50480924/regex-for-s3-bucket-name
    hostname_regex =
      ~r/(?!(^((2(5[0-5]|[0-4][0-9])|[01]?[0-9]{1,2})\.){3}(2(5[0-5]|[0-4][0-9])|[01]?[0-9]{1,2})$|^xn--|.+-s3alias$))^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$/

    if uri.scheme != nil && uri.host && Regex.match?(hostname_regex, uri.host) do
      true
    else
      false
    end
  end
end